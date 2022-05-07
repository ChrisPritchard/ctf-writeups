#!/usr/bin/expect -f

spawn ssh -p 2220 bandit31@bandit.labs.overthewire.org
expect "*: "
send "47e603bb428404d265f59c42920d81e5\r"
expect "*\$ "

send "git clone ssh://bandit31-git@localhost/home/bandit31-git/repo /tmp/.git31\r"
expect "*(yes/no)? "
send "yes\r"
expect "*password: "
send "47e603bb428404d265f59c42920d81e5\r"
expect "*\$ "

send "cd /tmp/.git31\r"
expect "*\$ "

send "cat README.md\r"
expect "*\$ "

send "echo May I come in? > key.txt\r"
expect "*\$ "

send "git add -f key.txt\r"
expect "*\$ "

send "git commit -m \"here we go\"\r"
expect "*\$ "

send "git push\r"
expect "*(yes/no)? "
send "yes\r"
expect "*password: "
send "47e603bb428404d265f59c42920d81e5\r"
expect "*\$ "

send "cd ~\r"
expect "*\$ "
send "rm -rf /tmp/.git31\r"
expect "*\$ "