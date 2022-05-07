#!/usr/bin/expect -f

spawn ssh -l bandit4 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "pIwrPrtPN36QITSp3EQaw936yaFoFgAB\r"
expect "*\$ "

send "file -F \" \" ./inhere/* | grep ASCII | { read first _; cat \$first; }\r"
expect "*\$ "

send "exit\r"
