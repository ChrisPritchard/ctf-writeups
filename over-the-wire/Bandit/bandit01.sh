#!/usr/bin/expect -f

spawn ssh -l bandit1 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "boJ9jbbUNNfktd78OOpsqOltutMc3MY1\r"
expect "*\$ "

send "cat ./-\r"
expect "*\$ "

send "exit\r"
