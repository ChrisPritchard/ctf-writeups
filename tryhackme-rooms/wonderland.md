# Wonderland

Fall down the rabbit hole and enter wonderland

Bit of a complex one, though ultimately trivial (got stuck in one place).

1. nmap revealed port 80 and 22
2. the website said "follow the white rabbit", with an image of the rabbit. I figured this might be the /img/ dir, but there was nothing there but other images (was a bit worried this might be a stego challenge for a second)
3. dirb revealed /r and in there, /a. so at a guess, /r/a/b/b/i/t, which indeed led to a new page.
4. in the source of that page was alice:[alongpassword] which i tested with ssh and it worked
5. alice's home dir contained a root.txt file I couldn't read, and a python script that recited lines using 'import random'
6. sudo -l revealed alice could run the script as rabbit, so i guessed this was a python import exploit. i created a random.py file locally that connected back to a reverse shell listener
7. running as sudo gave me access as rabbit. rabbit's home dir contained a suid file (elevating to hatter) called teaParty. when ran this invoked date and then seg faulted.
8. after being worried this might be a buffer overflow challenge (which i hate like stego) its actually a path exploit, over date. running `echo /bin/bash > date && chmod +x date` then the suid file gave me access as hatter
9. in hatter's dir was his plaintext password which i used to `su hatter` back on my original ssh session, to have a slightly more stable user session (and to test this was indeed hatter's password)
10. this was when i learned something new. to find the final privesc, I used `getcap / -r 2>/dev/null`, which i haven't seen/used before. this revealed perl had the getsuid cap. i got this from a walkthrough, though my handy linpeas would have told me this too. capabilities abuse is not something I've seen before or was aware of.
11. gtfo-bins gave me a command to use with this to get root. the user flag was in root's dir and the root flag, as mentioned, back in alice's

Easy! Have never seen that getcap before! will have to remember this!
