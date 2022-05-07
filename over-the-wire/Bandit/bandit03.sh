#!/usr/bin/expect -f

spawn ssh -l bandit3 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "UmHadQclWmgdLOKQ3YNgjWxGoRMb5luK\r"
expect "*\$ "

send "cat ./inhere/.hidden\r"
expect "*\$ "

send "exit\r"
