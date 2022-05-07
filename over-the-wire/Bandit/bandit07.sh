#!/usr/bin/expect -f

spawn ssh -l bandit7 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "HKBPTKQnIay4Fw76bEy8PVxKEDQRKTzs\r"
expect "*\$ "

send "grep -r *data.txt -e \"millionth\" 2>/dev/null | awk '{ print \$NF; }'\r"
expect "*\$ "

send "exit\r"
