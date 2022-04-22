# Carnage Koth Machine

Path to foothold:

1. Can ssh in as `bobba`, with ``bobba:-`G)8(t/NDkZ"u^{``. These credentials come from a sqlite database, `web.db`, found in the web2 (port 82) website's folder, accessible after compromise
  - the site on :81 is vulnerable to sql injection over this database, which is another way to retrieve the creds
2. Port 80 has a hidden site at `/3ef043d9e9c5d19b9db6d87c6f23b290/dice.php?action=metsys&text=di` - it gives command execution as `yoda`, with the text needing to be reversed
3. Port 82 hosts a file upload site, that only checks the stated upload content type. By setting this as `image/png` and adding an extension like `.png.php`, an otherwise standard php web shell can be uploaded. This will get you access as the user `duku`
  - Can go straight into the system as `duku` using the following ssh key:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACATQLVIr77yK4TwcZZ1u0DX/qaSue5NNUkDz4roBYT0zgAAAIjrCGAZ6whg
GQAAAAtzc2gtZWQyNTUxOQAAACATQLVIr77yK4TwcZZ1u0DX/qaSue5NNUkDz4roBYT0zg
AAAEC3POa13ftnfCfC3LhqDZ04lSEUQK3+OMtomXRmTI1WjhNAtUivvvIrhPBxlnW7QNf+
ppK57k01SQPPiugFhPTOAAAABGR1a3UB
-----END OPENSSH PRIVATE KEY-----
```

Path to root:

1. User bobba is the only user who can use find. Find has the suid bit set, and can give access to root via `/usr/bin/find . -exec /bin/sh \; -quit`
2. duku can use /usr/bin/netkit-ftp. `!/bin/sh` works to get root
3. yoda can use /usr/bin/vim.tiny - it can be used to edit /etc/passwd for example, though best done after creating authorized_keys and ssh'ing in properly

Note, the king.txt file has the append only flag set, and there is no chattr on the machine I could find. To add user use `echo Aquinas >> king.txt`

## flags

- /home/bobba/flag1.txt (rot13)
- /home/yoda/flag2.txt (hex)
- /home/duku/flag3.txt
- /root/flag4.txt
- /var/www/html/web1/web.db
- /var/www/html/web2/flag.txt
- /var/www/html/web3/flag.txt
