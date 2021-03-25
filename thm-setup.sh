#! /bin/bash

# THM attack box setup
# intended to be copy pasted into the shell, or run in one command via:
#   curl https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

echo link wordlists local
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
ln -s /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt directory-list-2.3-medium.txt

echo linpeas local copy
wget https://raw.githubusercontent.com/carlospolop/privilege-escalation-awesome-scripts-suite/master/linPEAS/linpeas.sh

echo quick commands
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -sV" > rustscan.sh
echo "python3 -m http.server 1234" > webserver.sh

echo tool download scripts
echo "go get -u github.com/ffuf/ffuf" > get-ffuf.sh
echo "wget https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_linux_amd64.gz && gunzip chisel_1.7.6_linux_amd64.gz && mv chisel_1.7.6_linux_amd64 chisel" > get-chisel.sh
