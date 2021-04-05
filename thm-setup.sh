#! /bin/bash

# THM attack box setup
# intended to be copy pasted into the shell, or run in one command via:
#   curl https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash

# linking wordlists locally
ln -s /usr/share/wordlists/rockyou.txt rockyou.txt
ln -s /usr/share/wordlists/SecLists/Discovery/Web-Content/directory-list-2.3-medium.txt directory-list-2.3-medium.txt

# linpeas local copy
wget https://raw.githubusercontent.com/carlospolop/privilege-escalation-awesome-scripts-suite/master/linPEAS/linpeas.sh

# quick commands
echo "docker run -it --rm --name rustscan rustscan/rustscan:latest -a \$1 -- -sV" > rustscan.sh
chmod +x rustscan.sh

# tool download scripts
echo "echo getting ffuf... && go get -u github.com/ffuf/ffuf" > get-ffuf.sh
chmod +x get-ffuf.sh
echo "wget https://github.com/jpillora/chisel/releases/download/v1.7.6/chisel_1.7.6_linux_amd64.gz && gunzip chisel_1.7.6_linux_amd64.gz && mv chisel_1.7.6_linux_amd64 chisel && chmod +x chisel" > get-chisel.sh
chmod +x get-chisel.sh

# static binary download scripts
echo "wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/nmap && wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat && wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat" > get-static-binaries.sh
chmod +x get-static-binaries.sh
