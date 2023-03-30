# Plotted EMR

https://tryhackme.com/room/plottedemr

Rated HARD

Tricky initial foothold, but after not too bad.

1. There are a number of ports open, notably FTP, a mysql server on 5900 and a site at 8890 which if you fuzz, has an instance of OpenEMR under /portal. There are other ports open, e.g. a website on 80, but they're all red herrings.
2. The FTP service (which allows anomymous access) has, buried under several hidden directories, a txt file. This includes a hint to 'try admin'
3. The MYSQL service on 5900 allows access without a password as admin, e.g. `mysql -u admin -H <IP>`. This user is a super admin for mysql, but there is no more access here or privesc, however, this is useful later.
4. The version of OpenEMR under :8890/portal is 5.0.1.3. This has a number of vulns, including an auth bypass, but the bypass has been disabled.
5. Instead, access /portal/admin.php and create a new site. You can clone the existing database, just make sure to set the hostnames to the IP of the server (localhost seems to fail) and enter 'admin' as the root username, no password required.
6. When the site is created, you should be able to login to the new site.
7. To get a foothold, I used an RCE in the globals 'print command value'.
  - navigate to Administration > Globals
  - under the 'Miscellaneous' tab, there is a field labeled 'Print Command'.
  - as seen in an [open pentest report online](https://www.open-emr.org/wiki/images/1/11/Openemr_insecurity.pdf), this is pretty much straight rce: enter a value into this field like `echo "<?php system('ls') ?>" > rce.php;`
  - to create the rce file, send a post request to `/portal/interface/billing/sl_eob_search.php` with the form values `form_print=1`
  - you can then navigate to `/portal/interface/billing/rce.php` to trigger whatever
8. This allowed me to get a shell on the machine as www-data (I used a reverse_ssh client which I downloaded with the rce). The first flag is under `/var/www`.
9. Enumerating the machine reveals a cronjob that runs rsync as the user plot_admin. The specific line is:
  - `* *     * * *   plot_admin cd /var/www/html/portal/config && rsync -t * plot_admin@127.0.0.1:~/backup`
10. This is a wildcard exploit - navigate to /var/www/html/portal/config and then use `touch -- '-e sh script'` to create a file that will be interpreted as an argument when rsync runs, specifically running a script named 'script' in the same directory. This was used to laterally move to plot_admin, and the user flag in their home directory.
11. Perl has the CAP_FOWNER capability, which allowed perl to change the permissions on any file. With the following command I made /etc/passwd world writable: `perl -e 'chmod 0666, "/etc/passwd"`. I then added my standard root user to /etc/passwd to allow me to switch to root.

Nice room, a bit twisty.
