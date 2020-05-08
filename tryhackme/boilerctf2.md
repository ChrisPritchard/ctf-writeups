# Boiler CTF

A pretty easy one, but learned some new tricks so documenting:

1. Enumeration revealed ftp, a website on 80, a website on 10000 and ssh running on 55007
2. Logging into ftp allowed anonymous access (as hinted by the first question), however I couldn't see any files.

    > First thing I learned, `ls -a` on ftp works (ls -lA doesn't). This showed a hidden text file which solved the first question.

3. A dirb and banner search on the two websites revealed 80 ran joomla under /joomla, while 10000 ran webmin. The latter was an answer to a follow up question.

4. Version grabbing and exploit searches for both, plus tests using metasploit, failed to work or find anything interesting. The questions in the room quickly suggested that webmin was not the target, so I focused on joomla.

    > Joomscan is an enumeration tool that isn't installed in the tryhackme kali instance by default. `sudo apt install joomscan` will grab it. However, unlike wpscan, joomscan seems pretty limited and did not help here.

5. I ran dirb on joomla and it found a lot of listable directories. The room questions hinted I might find an interesting file in one of them.

    > Second thing I learned (if you ignore joomscan) is a way to use dirb to search these directories: 
    > 
    > `dirb http://10.10.177.33/joomla -X ,.txt -w | grep "+ "`
    >
    > The `-X` specifies two extensions (seperated by `,`): nothing, which means folders get picked up (important for enumeration) and .txt, which I guessed would be a relevant file extension. `-w` ensures that when it finds a listable directory it doesnt skip to the next path but keeps trying within. Finally, `| grep "+ "` trims the noise to just the results.

6. Via dirb, I found `/joomla/_test/log.txt`. The contents of which gave me the ssh password for a user named `basterd`

7. Once in, basterd's home directory contained `backup.sh`, which contained the other user `stoner`'s password. However, I was having trouble switching to that user. I tried sudo -l on basterd but got nothing.

8. A quick `find / -user root -perm -u=s 2>/dev/null` revealed one interesting suid exe, `/usr/bin/find`. Find is trivially exploitable to get root when it has suid: `/usr/bin/find . -exec /bin/sh -p \; -quit`.

9. With a root shell I grabbed the user flag from /home/stoner (it was a hidden file called `.secret`) and the root flag from `/root/root.txt`

Easy. So in summary, `ls -a` works to find hidden files in ftp, `joomscan` sucks, and `dirb` with extensions and greb is awesome.