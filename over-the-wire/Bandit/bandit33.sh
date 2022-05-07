#!/usr/bin/expect -f

spawn ssh -p 2220 bandit33@bandit.labs.overthewire.org
expect "*: "
send "c9c3199ddf4121b10cf581a98d51caee\r"
expect "*\$ "

send "cat README.txt\r"
expect "*\$ "
