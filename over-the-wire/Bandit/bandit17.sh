#!/usr/bin/expect -f

spawn ssh -l bandit17 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "xLYVMN9WE5zQ5vHacb0sZEVqbrp7nBTn\r"
expect "*\$ "

send "diff passwords.old passwords.new | tail -n1\r"
expect "*\$ "

send "exit\r"
