#!/usr/bin/expect -f

spawn ssh -p 2220 bandit20@bandit.labs.overthewire.org
expect "*: "
send "GbKksEFF4yrVs6il55v6gwY5aVje5f0j\r"
expect "*\$ "

send "echo GbKksEFF4yrVs6il55v6gwY5aVje5f0j | nc -l -p 3000 localhost &\r"
expect "*\$ "

send "./suconnect 3000\r"
expect "*\$ "

send "exit\r"
send "\r"
