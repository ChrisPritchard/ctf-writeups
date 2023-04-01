# Devie

https://tryhackme.com/room/devie

Rated: Medium

A three-step room, that wasn't too tricky.

1. A scan reveals ports 22 and 5000. On 5000 is a python application that performs math operations for you. Helpfully, they provide the source for it. Reviewing this reveals that of the three operations provided, the 'bisect' is vulnerable:
  - Unlike the others, its validation on the inputs (in bisection.py) just checks they are string fields: `xa = StringField(default=1,validators=[validators.InputRequired()])`
  - Once validated, the fields are concated and then passed to an eval function in app.py (lines 71 and 72): `added = xa + " + " + xb` and `c = eval(added)`

2. This can be exploited to run commands via passing in a command like `__import__('os').system('touch test')#`. How you pivot from this to a reverse shell is up to the reader, but there is nc and wget on the box so you have plenty of options.

3. On the machine as the 'bruce' user, you can get the first flag. In their home directory is a note that contains the following:

  ```
  Hello Bruce,

  I have encoded my password using the super secure XOR format.

  I made the key quite lengthy and spiced it up with some base64 at the end to make it even more secure. I'll share the decoding script for it soon. However, you can use my script located in the /opt/ directory.

  For now look at this super secure string:
  [REDACTED]

  Gordon
  ```
  
4. The encrypt script can be run as sudo, e.g. `sudo -u gordon /opt/encrypt.py` and will return a base64 encoded string of whatever you ask it to encrypt. I figured the process was `plaintext -> xor with secret -> base64`. There are probably smarter ways to figure this out, but I went fairly manual:
  - First I encrypted using the script a sequence of 'a' characters, e.g. `aaaaaaaaaaaaaaaaaaa`.
  - I put the result in cyberchef, decoded from base64, and then used 'to decimal' to get the decimal values of the bytes.
  - In a separate cyberchef window, I placed the same sequence of 'a' characters and added a xor operation with a utf8 key, plus the 'to decimal' operation
  - To work out the key, I tried characters in the second xoring window until the value of the decimal output matched the from b64/to decimal first window.
  - E.g. the first character value after from base64 was 18. In the second window, the value unxored was 97. I tried different characters as the first character of the key until its value xored became 18. The second value in the first window was 20, so I tried again with the key's second character until the second value was 20.
  - And so on. This became easier as the key unravelled, as its plain text and I could guess the words used.
  - With the final key and the secret in the note above, I could reverse it to get gordon's password.

4. As gordon the second flag was in their home directory. Additionally there were two folders, reports and backups. A bit of recon found /usr/bin/backup, a script gordon could read but not run, that ran `cp *` from reports into backups. I used pspy to see that root was running this every minute.

5. To exploit this wasn't too tricky. I copied passwd from /etc into reports, and added a custom root user to it. I then removed the backups folder and replaced it with a symlink to /etc with `ln -s /etc backups`. When root ran the command, they unknowingly replaced the real passwd file with my modified variant, and I was able to su to my custom root user and get the final flag.
