# Break Out The Cage

Fun, because Cage is fun :)

## Recon

1. nmap revealed 21, 22 and 80
2. nikto and dirb on the website revealed a few listable folders, including `/scripts` and `/contracts`, which contained nothing (movie contracts in the first instance)
3. ftp allowed anonymous, and contained a single file `dad_tasks`
4. This file was base 64 encoded, and then looked vignere encoded. I broke the latter with https://www.guballa.de/vigenere-solver which revealed the password `namelesstwo`
5. This gave a list of humourous tasks, and what I guessed successfully was the ssh password: `Mydadisghostrideraintthatcoolnocausehesonfirejokes`

## Logged in over SSH

6. Once on the machine, `sudo -l` revealed the user could run `/usr/bin/bees`. This is a shell script that just runs the `wall` command. However, the wall command is not something I can delete or move, by the looks of it.
7. Navigating to the website directory, I found an `/auditions` folder containing an MP3 that obviously contained a spectogram.