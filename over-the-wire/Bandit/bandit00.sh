#!/usr/bin/expect -f

spawn ssh -l bandit0 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "bandit0\r"
expect "*\$ "

send "cat readme\r"
expect "*\$ "

send "exit\r"
