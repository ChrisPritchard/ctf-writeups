# Aratus

"Do you like reading? Do you like to go through tons of text? Aratus has what you need!"

https://tryhackme.com/room/aratus

This was an interesting room. The foothold was non-obvious, the lateral movement was non-obvious and the path to root was non-obvious :D Took me around two hours.

1. An initial scan reveals ftp, http and smb. There was nothing on the ftp site, and bruteforcing the http site got me nowhere (there is something to find, but the directory wordlist 2.3 medium I usually use found nothing).
2. On smb, under a 'temporary share' is the `simeon` user's home folder. The username is determined from a message text file within, from another user named `theodore`. Aside from this message, the only other usuable information were nine folders, chapter1-9, each which contained multiple paragraphs and each of which contained multiple text files.
3. Each text file was 3229 bytes, and looked to filled with loren ipsum. To confirm they were the same, I ran `find . -name "*.txt" -exec md5sum {} \;`. This discovered *one* file was in fact different. Within it I found a **SSH private key**.
4. The key had a passphrase, which I broke with john the ripper and rockyou easily enough. This allowed me to SSH on to the box as `simeon`.
5. Doing enumeration, little was found. However I did find a html folder under the website, `test-auth`, that contained an .htpasswd file. This had the username theodore, the other user, but after cracking the password using hashcat it turned out not to be correct for the user on the box.
6. Another thing found was tcpdump, with cap_net_admin meaning all users could run it. Given the website from before, this suggested to me that there *might* be an automated service calling the webpage (the index.html contained 'if you can see this the curl command worked!'). Using the following command, `tcpdump -i lo -A port not 22`, I listened for local traffic and was eventually rewarded with an HTTP request. This one contained a different password in its creds, which was valid for the theodore user.
7. Theodore contained the **user flag**.
8. sudo -l revealed theodore could run a script under /opt/scripts: `(automation) NOPASSWD: /opt/scripts/infra_as_code.sh`. This script would run the ansible playbook on the machine as the user `automation`. An examination of the ansible folder, also under opt, did not reveal any files the user theodore could modify. However, there was one file that had the permissions: `-rw-rw-r--+ 1 automation automation`. Running `getfacl` against this, I found the hidden extra set of permissions:

```
# file: [redacted]
# owner: automation
# group: automation
user::rw-
user:theodore:rw-
group::rw-
mask::rw-
other::r--
```

9. Within this file was a number of generic template operations. I found one that was suitable, and altered its task to the following:

```yaml
- name: [redacted]
  copy:
    src: "/bin/sh"
    dest: "/tmp/sh"
    owner: root
    group: root
    mode: 04777
  notify: [redacted]
  when: [redacted] | bool
```

10. After running the sudo script via `sudo -u automation  /opt/scripts/infra_as_code.sh`, I checked tmp and found a suid sh binary which allowed privesc to `root` :)

Learnt a few things, which is always the best!
