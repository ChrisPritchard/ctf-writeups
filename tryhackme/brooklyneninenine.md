# Brooklyn Nine Nine

This room is aimed for beginner level hackers but anyone can try to hack this box. There are two main intended ways to root the box.

Super simple.

1. nmap revealed 21, 22, 80
2. ftp was anonymous and contained a note to jake saying his password was easy - this was not relevant to my attempt though
3. website had a full size image and a note in source talking about stego. ugh
4. using stegcracker and fasttrack.txt I extracted a text file from the image (password was admin). text file contained 'holts password'
5. ssh'ing in as holt, user flag was in his dir
6. sudo -l revealed he could run nano as sudo. via gtfo-bins i found the nano commands to get a root shell.

simple.

looking up other writeups, the alternative way to get in was to brute force jake's ssh (via rockyou it only took a few seconds), then use his sudo access to `less` to get root.
