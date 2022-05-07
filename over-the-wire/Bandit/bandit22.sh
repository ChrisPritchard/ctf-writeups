#!/usr/bin/expect -f

spawn ssh -p 2220 bandit22@bandit.labs.overthewire.org
expect "*: "
send "Yk7owGAcWjwMVRwrTesJEwB7WVOiILLI\r"
expect "*\$ "

send "cat /etc/cron.d/cronjob_bandit23\r"
expect "*\$ "

send "cat /usr/bin/cronjob_bandit23.sh\r"
expect "*\$ "

send "echo I am user bandit23 | md5sum | cut -d ' ' -f 1\r"
expect "*\$ "

send "cat /tmp/8ca319486bfbbc3663ea0fbe81326349\r"
expect "*\$ "

send "exit\r"
