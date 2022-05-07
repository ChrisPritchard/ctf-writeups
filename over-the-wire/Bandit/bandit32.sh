#!/usr/bin/expect -f

spawn ssh -p 2220 bandit32@bandit.labs.overthewire.org
expect "*: "
send "56a9bf19c63d650ce78e6ec0354ee45e\r"
expect ">> "

send "\$0\r"
expect "\$ "

send "/bin/bash\r"
expect "*\$ "

send "cat /etc/bandit_pass/bandit33\r"
expect "*\$ "