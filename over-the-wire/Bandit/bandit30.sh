#!/usr/bin/expect -f

spawn ssh -p 2220 bandit30@bandit.labs.overthewire.org
expect "*: "
send "5b90576bedb2cc04c86a9e924ce42faf\r"
expect "*\$ "

send "git clone ssh://bandit30-git@localhost/home/bandit30-git/repo /tmp/git30\r"
expect "*(yes/no)? "
send "yes\r"
expect "*password: "
send "5b90576bedb2cc04c86a9e924ce42faf\r"
expect "*\$ "

send "cd /tmp/git30\r"
expect "*\$ "

send "cat README.md\r"
expect "*\$ "

send "git tag\r"
expect "*\$ "

send "git show secret\r"
expect "*\$ "

send "cd ~\r"
expect "*\$ "
send "rm -rf /tmp/git30\r"
expect "*\$ "