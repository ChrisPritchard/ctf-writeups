#!/usr/bin/expect -f

spawn ssh -p 2220 bandit29@bandit.labs.overthewire.org
expect "*: "
send "bbc96594b4e001778eee9975372716b2\r"
expect "*\$ "

send "rm -rf /tmp/git29\r"
expect "*\$ "

send "git clone ssh://bandit29-git@localhost/home/bandit29-git/repo /tmp/git29\r"
expect "*(yes/no)? "
send "yes\r"
expect "*password: "
send "bbc96594b4e001778eee9975372716b2\r"
expect "*\$ "

send "ls /tmp/git29\r"
expect "*\$ "
send "cat /tmp/git29/README.md\r"
expect "*\$ "

send "cd /tmp/git29\r"
expect "*\$ "
send "git branch -a\r"
expect "*\$ "
send "git checkout dev\r"
expect "*\$ "

send "cat README.md\r"
expect "*\$ "

send "cd ~\r"
expect "*\$ "
send "rm -rf /tmp/git29\r"
expect "*\$ "