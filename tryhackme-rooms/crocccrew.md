# CroccCrew

Rated "INSANE"

This room isn't actually that hard, EXCEPT for the initial AD credentials, which depending on your approach might be impossible to find.

1. Its a windows DC, so lots of ports are open including SMB, WinRM and LDAP. There is a website on 80 that has been defaced, and includes a few red herrings.
2. To find some AD credentials, you need to connect over RDP and view the login screen. This is impossible by default if accessing from windows (as I was), as network level authentication requires you to have a valid username and password before a session is created. However, if you save the RDP connection config as a .rdp file, then open it and add the line `enablecredsspsupport:i:0` this will open a session to the login screen whose background image has on it a username (`Visitor`) and password - these creds won't work for RDP but they are valid domain creds.
3. With these creds you can access SMB and get the user flag, but more importantly they can be used with `impacket-GetUserSPNs -dc-ip 10.10.253.208 COOCTUS.CORP/Visitor:REDACTED -request`, which reveals a SPN for the user `password-reset` who has constrained delegation rights. The SPN can be cracked using hashcat to get their password.
4. The delegation can be used to get a ticket for the administrator user with `impacket-getST -dc-ip 10.10.253.208 COOCTUS.CORP/password-reset:REDACTED -impersonate Administrator -spn oakley/DC.COOCTUS.CORP`
5. Use `export KRB5CCNAME=Administrator.ccache` to set this as the current cc for kerb commands, add the DC to hosts (`IP DC.COOCTUS.CORP`) then use `impacket-secretsdump -k -no-pass DC.COOCTUS.CORP -dc-ip 10.10.253.208` to dump all hashes
6. With the admin hash, you can use evil-winrm to get an administrator session: `evil-winrm -i 10.10.253.208 -u Administrator -H REDACTED`.

There are flags under /shares/Home and /perflogs/admin
