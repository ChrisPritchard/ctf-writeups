# Lian_YU

"Welcome to Lian_YU, this Arrowverse themed beginner CTF box! Capture the flags and have fun."

A simple box, but I learned something from it so worth writing down.

1. Recon revealed 21, 22, 80, 111 and some ~40000 port. The latter two ports were irrelevant.

2. The website at 80 was a static page. The first question of the room said find the hidden directory in numbers, with a pattern of `****`. The room also had a gobuster tag, so I used gobuster. However, I could only find one directory, `/island`, no matter what word list I used! On /island was the hidden phrase `vigilante` in white text on a white background.

    > This is the thing I learned in this room, which I guess I didn't know (or had forgotten): **gobuster is NOT recursive**. I Usually use dirb, which IS recursive; with gobuster, if you find a dir, to enumerate it you need to run gobuster again.

3. Running gobuster on `/island` I found the directory `/island/2100`, which fit the first question of the room. On that page was a video, and in the source of the page the comment: `you can avail your .ticket here but how?`.

4. I ran gobuster with `-x .ticket` and it quickly found a file called `green_arrow.ticket`. Inside this was the string `RTy8yhBQdscX` which, via cyberchef, I decoded from base58 as `!#th3h00d`.

5. The room suggested this was the ftp password, and so I tried on the ftp server for a bit. It was configured so that if you specified an unrecognised user name you got kicked. I tried a few options, before eventually using `vigilante` from before. This got me into the server where I found and downloaded three images.

6. The room had a stego tag, and these looked stego like. One of the images, `Leave me alone.png` was not considered a valid PNG file. I ran `strings` against it and saw IHDR and IEND, which are png-markers, so I guessed it might have just had its headers screwed. Sure enough, `hexeditor` on that image revealed the first eight or so bytes were nonsense. I replaced this with valid values (just taken from the other png I downloaded from the server) and the image worked correctly. Opening it showed an image with the text `my password is password` or something similar.

7. I recognised the character in the image from one of the other files, `aa.jpg`. Using `steghide extract -sf aa.jpg` on that image with `password` as the passphrase, it extracted `ss.zip`.

8. Inside was a passwd.txt file (that contained nothing of note), and another file called `shado`. The latter contained the password `M3tahuman`, which I guessed was the ssh password.

9. Getting the username was not obvious. Unsure if I missed something, but after a number of tries I eventually guessed it: both `aa.jpg` and the fixed `Leave me alone.png` were of a character in the Arrow TV show named `Slade`. I tried to ssh in with `slade` as the username and it worked!

10. User flag was in the root folder. `sudo -l` revealed the user could run `pkexec` as root, a binary that allows you to run anything else as root, so I ran `sudo /usr/bin/pkexec /bin/sh` to get a root shell and get the root flag. Easy.
