# Hacker vs Hacker Official Walkthrough

This is the first room I have had published on TryHackMe, ranked easy. The key to it is to think like an attacker attacking an existing attacker :) That is, you need to imagine what the hacker tried to do and then leverage their work to compromise the machine.

1. Enumeration of the machine reveals two ports: 22 and 80.
2. Under 80 is a brochureware site for some recruitment company. Enumeration reveals:
    - it is mainly static html, with a few comments in source code.
    - there is a 'cv upload form', with a comment saying it will upload to `/cvs`
3. Attempting to upload a file shows upload.php has been disabled. The full content is as such, revealing the (former) code of the page:

    ```
    Hacked! If you dont want me to upload my shell, do better at filtering!

    <!-- seriously, dumb stuff:

    $target_dir = "cvs/";
    $target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);

    if (!strpos($target_file, ".pdf")) {
    echo "Only PDF CVs are accepted.";
    } else if (file_exists($target_file)) {
    echo "This CV has already been uploaded!";
    } else if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
    echo "Success! We will get back to you.";
    } else {
    echo "Something went wrong :|";
    }
    -->
    ```

4. As seen, the code is php and the hacker has uploaded a 'shell'. Additionally, the code above implements a single filter, that the file name includes `.pdf`. Trying `/cvs/shell.pdf.php` loads the shell.

5. Bruteforcing command parameters, we find `cmd` as in `?cmd=id` works, and we have command execution as the user `www-data`.

6. With this we can enumerate the machine (either through the command arg, or via establishing a reverse shell for example). There is one user, `lachlan`, whose home directory contains the user flag. Additionally there is a .bash_history file.

7. Reading the bash history file, it shows the attacker changed lachlan's password, created a cron job, and then attempted to nullify the bash history but typed `ls` instead of `ln` in `ln -sf /dev/null`. Accordingly we have recovered lachlan's password.

8. SSH'ing into the box, withing 5-10 seconds our connection is dropped. This seems consistent - some sort of process is ending our terminal session. We can use the limited time available or the existing webshell to read the cron job that was in the bash history:

    ```
    PATH=/home/lachlan/bin:/bin:/usr/bin
    # * * * * * root backup.sh
    * * * * * root /bin/sleep 1  && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    * * * * * root /bin/sleep 11 && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    * * * * * root /bin/sleep 21 && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    * * * * * root /bin/sleep 31 && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    * * * * * root /bin/sleep 41 && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    * * * * * root /bin/sleep 51 && for f in `/bin/ls /dev/pts`; do /usr/bin/echo nope > /dev/pts/$f && pkill -9 -t pts/$f; done
    ```
    
    As this is killing our session via pts, we could if we wish avoid the problem by SSH'ing in with `-T`, which doesn't create a PTY and so won't be killable this way.

9. Analysing the cronjobs further, two facts are presented:
    - the path is set to include /home/lachlan/bin, which we control
    - all executables are fully qualified except one, `pkill`

10. Creating a new executable file in `/home/lachlan/bin` named `pkill`, we can gain command execution as root.
    - one way this can be done is setting the contents to `cp /bin/sh /tmp/sh && chmod u+s /tmp/sh`
