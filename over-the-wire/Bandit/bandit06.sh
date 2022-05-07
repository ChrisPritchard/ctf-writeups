#!/usr/bin/expect -f

spawn ssh -l bandit6 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "DXjZPULLxYr17uwoI01bNLQbtFemEgo7\r"
expect "*\$ "

send "find / -size 33c -user bandit7 -exec cat {} \\; 2>/dev/null\r"
expect "*\$ "

send "exit\r"
