#!/usr/bin/expect -f

spawn ssh -l bandit2 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "CV1DtqXWVFXTvM2F0k09SHz0YwRINYA9\r"
expect "*\$ "

send "cat spaces\\ in\\ this\\ filename\r"
expect "*\$ "

send "exit\r"
