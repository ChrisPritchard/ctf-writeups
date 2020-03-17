# Sunset: Dusk

https://www.vulnhub.com/entry/sunset-dusk,404/

## Reconnaissance

An intense nmap scan revealed:

```
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     pyftpdlib 1.5.5
| ftp-syst: 
|   STAT: 
| FTP server status:
|  Connected to: 192.168.53.6:21
|  Waiting for username.
|  TYPE: ASCII; STRUcture: File; MODE: Stream
|  Data connection closed.
|_End of status.
22/tcp   open  ssh     OpenSSH 7.9p1 Debian 10+deb10u1 (protocol 2.0)
| ssh-hostkey: 
|   2048 b5:ff:69:2a:03:fd:6d:04:ed:2a:06:aa:bf:b2:6a:7c (RSA)
|   256 0b:6f:20:d6:7c:6c:84:be:d8:40:61:69:a2:c6:e8:8a (ECDSA)
|_  256 85:ff:47:d9:92:50:cb:f7:44:6c:b4:f4:5c:e9:1c:ed (ED25519)
25/tcp   open  smtp    Postfix smtpd
|_smtp-commands: dusk.dusk, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN, SMTPUTF8, CHUNKING, 
| ssl-cert: Subject: commonName=dusk.dusk
| Subject Alternative Name: DNS:dusk.dusk
| Not valid before: 2019-11-27T21:09:14
|_Not valid after:  2029-11-24T21:09:14
|_ssl-date: TLS randomness does not represent time
80/tcp   open  http    Apache httpd 2.4.38 ((Debian))
|_http-server-header: Apache/2.4.38 (Debian)
|_http-title: Apache2 Debian Default Page: It works
3306/tcp open  mysql   MySQL 5.5.5-10.3.18-MariaDB-0+deb10u1
| mysql-info: 
|   Protocol: 10
|   Version: 5.5.5-10.3.18-MariaDB-0+deb10u1
|   Thread ID: 40
|   Capabilities flags: 63486
|   Some Capabilities: InteractiveClient, Support41Auth, Speaks41ProtocolNew, SupportsLoadDataLocal, SupportsTransactions, ConnectWithDatabase, IgnoreSpaceBeforeParenthesis, DontAllowDatabaseTableColumn, IgnoreSigpipes, Speaks41ProtocolOld, ODBCClient, FoundRows, LongColumnFlag, SupportsCompression, SupportsMultipleResults, SupportsMultipleStatments, SupportsAuthPlugins
|   Status: Autocommit
|   Salt: AcN=%B[&HyJDTZF2e'0[
|_  Auth Plugin Name: mysql_native_password
8080/tcp open  http    PHP cli server 5.5 or later (PHP 7.3.11-1)
|_http-open-proxy: Proxy might be redirecting requests
|_http-title: Site doesn't have a title (text/html; charset=UTF-8).
Service Info: Host:  dusk.dusk; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

80 is just the default debian page again, but 8080 seems to be a php server running off /var/tmp, listing its files and running the index.php file there. Looks pretty juicy. nikto on either failed: nothing interesting on the default page, and 8080 is basically just a ftp listing.

Speaking of, ftp did not allow anonymous access. Neither did the mysql endpoint. Playing around with SMTP didn't achieve much. Ultimately a scan with legion, and a check for default credentials, revealed mysql used `root:password`. The following command got me in: `mysql -u root -p -h 192.168.53.6` followed by entering the password.
