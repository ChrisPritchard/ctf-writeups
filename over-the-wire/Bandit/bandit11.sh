#!/usr/bin/expect -f

spawn ssh -l bandit11 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "IFukwKGsFW8MOq3IRFqrxE1hxTNEbUPR\r"
expect "*\$ "

send "cat data.txt | tr 'a-zA-Z' 'n-za-mN-ZA-M' | awk '{ print \$NF; }'\r"
expect "*\$ "

send "exit\r"
