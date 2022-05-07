#!/usr/bin/expect -f

spawn ssh -p 2220 bandit28@bandit.labs.overthewire.org
expect "*: "
send "0ef186ac70e04ea33b4c1853d2526fa2\r"
expect "*\$ "

send "git clone ssh://bandit28-git@localhost/home/bandit28-git/repo /tmp/git28\r"
expect "*(yes/no)? "
send "yes\r"
expect "*password: "
send "0ef186ac70e04ea33b4c1853d2526fa2\r"
expect "*\$ "

send "ls /tmp/git28\r"
expect "*\$ "
send "cat /tmp/git28/README.md\r"
expect "*\$ "

send "cd /tmp/git28\r"
expect "*\$ "

send "git log -p -- README.md\r"
sleep .1
send "q\r"
expect "*\$ "

send "cd ~\r"
expect "*\$ "
send "rm -rf /tmp/git28\r"
expect "*\$ "