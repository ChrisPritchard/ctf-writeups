#!/usr/bin/expect -f

spawn ssh -l bandit16 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "cluFn7wTiGryunymYOu4RcffSxQluehd\r"
expect "*\$ "

send "nmap -p 31000-32000 localhost | grep /tcp | cut -c 1-5\r"
expect "*\$ "

send "echo cluFn7wTiGryunymYOu4RcffSxQluehd | openssl s_client -connect localhost:31790 -quiet | tail -n+2 > /tmp/bandit17.key\r"
expect "*\$ "

send "chmod 400 /tmp/bandit17.key\r"

send "ssh -i /tmp/bandit17.key -o StrictHostKeyChecking=no bandit17@localhost\r"
expect "*\$ "

send "cat /etc/bandit_pass/bandit17\r"
expect "*\$ "
send "exit\r"
expect "*\$ "

send "rm /tmp/bandit17.key"
expect "*\$ "

send "exit\r"