#!/usr/bin/expect -f

spawn ssh -l bandit5 -p 2220 bandit.labs.overthewire.org
expect "*: "
send "koReBOKuIDDepwhWk7jZC0RTdopnAYKh\r"
expect "*\$ "

send "find -size 1033c | { read first _; cat \$first; } | xargs\r"
expect "*\$ "

send "exit\r"
