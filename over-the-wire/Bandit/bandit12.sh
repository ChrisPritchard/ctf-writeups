#!/usr/bin/expect -f

spawn ssh -l bandit12 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "5Te8Y4drgCRfCx8ugdwuEX8KFC6k2EUu\r"
expect "*\$ "

send "xxd -r data.txt | gunzip | bunzip2 | gunzip | tar -xO | tar -xO | bunzip2 | tar -xO | gunzip | awk '{ print \$NF; }'\r"
expect "*\$ "

send "exit\r"
