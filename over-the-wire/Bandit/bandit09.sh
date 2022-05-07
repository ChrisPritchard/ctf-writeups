#!/usr/bin/expect -f

spawn ssh -l bandit9 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "UsvVyFSfZZWbi6wgC7dAFyFuR6jQQUhR\r"
expect "*\$ "

send "strings data.txt | grep \"===.\" | tail -1 | \{ read _ code; echo \$code; \}\r"
expect "*\$ "

send "exit\r"
