# Plotted-TMS

A relatively easy room. The hint was more 'enumeration', but it wasn't too difficult.

1. A rustscan revealed three ports, 22, 80 and 445. On 80 and 445 were apache websites with default sites.
2. Using gobuster dir with the directory list medium wordlist from seclists, I found a number of nonsense urls on the 80 site. On the 445 site there was `/management` though, hosting some sort of Traffic Management System (TMS)
3. The login for this site clould be bypassed using simple SQL injection, e.g. `' or 1=1 -- ` for the username.
4. In the site, there was various details on drivers and offenses. Drivers had a profile pic uploader, that was unrestricted. I uploaded a php webshell.
5. Using the webshell, I established a reverse shell as www-data.
6. The user to target was `plot_admin`. In `/etc/crontab`, this user ran a backup script under `/var/www/scripts` every minute. The script was owned by plot_admin and not editable, but the folder was in was owned by www-data, so the script could be moved and a new script with the same name put in its place.
7. Replacing the scripts contents with `/usr/bin/cp /usr/bin/sh /home/plot_admin/sh && /usr/bin/chmod u+s /home/plot_admin/sh` and making it executable, this created a suid sh in the plot_admin's home directory I could use to get execution as plot_admin via `sh -p`
8. To strengthen the shell, I created a .ssh directory with authorized_keys, and was able to ssh in normally as plot_admin
9. Enumerating using linpeas (this was very slow - I actually forgot it was running and the machines expired) revealed plot_admin could run openssl as root using *doas*, a sudo-equivalent.
10. With openssl there are a few options, but I used it to overwrite passwd with a new user entry that mapped to root:

```
TF=$(mktemp)
cat /etc/passwd > $TF
echo `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash` >> $TF
doas -u root openssl enc -in "$TF" -out /etc/passwd
```

I could then `su user3`, with password `pass123` to get root!
