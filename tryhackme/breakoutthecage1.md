# Break Out The Cage

Fun, because Cage is fun :)

## Recon

1. nmap revealed 21, 22 and 80
2. nikto and dirb on the website revealed a few listable folders, including `/scripts` and `/contracts`, which contained nothing (movie contracts in the first instance)
3. ftp allowed anonymous, and contained a single file `dad_tasks`
4. This file was base 64 encoded, and then looked vignere encoded. I broke the latter with https://www.guballa.de/vigenere-solver which revealed the password `namelesstwo`
5. This gave a list of humourous tasks, and what I guessed successfully was the ssh password: `Mydadisghostrideraintthatcoolnocausehesonfirejokes`
6. From the website I knew this user's name was `weston` and so I successfully logged in with that user.

## Shell as Weston

6. Once on the machine, `sudo -l` revealed the user could run `/usr/bin/bees`. This is a shell script that just runs the `wall` command. However, the wall command is not something I can delete or move, by the looks of it.
7. Navigating to the website directory, I found an `/auditions` folder containing an MP3 that obviously contained a spectogram. However, when I ran it through Sonic Visualiser it just gave me the password to the vignere encoding from before :D
8. The other user on the machine was `cage`, so I ran a `find / -user cage 2>/dev/null` and found a folder called `.dad_scripts` under `/opt`. While on the machine I had noticed periodic wall broadcasts, and in here I found a python script running wall against a randomly selected quote from `/opt/.dad_scripts/.files/.quotes`, as `cage`. And the .quotes file was writable :)