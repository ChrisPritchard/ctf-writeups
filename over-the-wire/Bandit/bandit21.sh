#!/usr/bin/expect -f

spawn ssh -p 2220 bandit21@bandit.labs.overthewire.org
expect "*: "
send "gE269g2h3mw3pwgrj0Ha9Uoqen1c9DGr\r"
expect "*\$ "

send "ls /etc/cron.d/\r"
expect "*\$ "

send "cat /etc/cron.d/cronjob_bandit22\r"
expect "*\$ "

send "cat /usr/bin/cronjob_bandit22.sh\r"
expect "*\$ "

send "cat /tmp/t7O6lds9S0RqQh9aMcz6ShpAoZKF7fgv\r"
expect "*\$ "

send "exit\r"
send "\r"
