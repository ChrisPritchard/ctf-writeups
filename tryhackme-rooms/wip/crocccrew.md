$servername = "db.cooctus.corp";
$username = "C00ctusAdm1n";
$password = "B4dt0th3b0n3";

COOCTUS.CORP0.
am
DC.COOCTUS.CORP

5985/tcp

backdoor.php looks like it might be a red herring - only a single command, hello, defined
there is also the dbconfig.php.bak with C00ctusAdm1n/B4dt0th3b0n3, possibly also a rabbit hole

To connect via RDP from windows without creds, save a RDP file with the address, open in notepad and add `enablecredsspsupport:i:0`.
this reveals some creds on the lock screen - bit cheap but hey
Visitor/GuestLogin! - works over smb

password-reset from spn
COOCTUS.CORP/password-reset resetpassword
