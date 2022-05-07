#!/usr/bin/expect -f

spawn ssh -l bandit10 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "truKLdjsbJ5g7yyJ2X2R0o3a5HQJFuLk\r"
expect "*\$ "

send "base64 -d data.txt | \{ read _ _ _ code; echo \$code; \}\r"
expect "*\$ "

send "exit\r"
