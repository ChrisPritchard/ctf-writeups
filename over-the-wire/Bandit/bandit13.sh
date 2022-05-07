#!/usr/bin/expect -f

spawn ssh -l bandit13 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "8ZjyCRiBWFYkneahHwxCv3wb2a1ORpYL\r"
expect "*\$ "

send "ssh -i sshkey.private -l bandit14 localhost\r"
expect "*? "
send "yes\r"
expect "*\$ "

send "cat /etc/bandit_pass/bandit14\r"
expect "*\$ "

send "exit\r"
send "exit\r"
