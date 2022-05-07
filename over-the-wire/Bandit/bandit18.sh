#!/usr/bin/expect -f

spawn ssh -l bandit18 -p 2220 bandit.labs.overthewire.org "cat readme"
expect "*: "
send "kfBf3eYk5BPBRzwjqutbbfE887SVc5Yd\r"
interact