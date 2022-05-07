#!/usr/bin/expect -f

spawn ssh -l bandit8 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "cvX2JJa4CFALtqS87jk27qwqGhBM9plV\r"
expect "*\$ "

send "cat data.txt | sort | uniq -c | grep \"1 .\" | \{ read _ code; echo \$code; \}\r"
expect "*\$ "

send "exit\r"
