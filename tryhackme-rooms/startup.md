# Startup

Abuse traditional vulnerabilities via untraditional means.

A pretty simple one, no hints required but for the first 'recipe' question, which was a file in / that I found after getting the root flag :D

1. nmap revealed 21, 22 and 80
2. 21 was anonymous ftp, containing two files, one of which suggested that the ftp dir might be accessible via the website
3. dirb on the website revealed /files, which exposed the ftp dir
4. I uploaded p0wny-shell via ftp, then accessed it to get a web shell as www-data
5. Running linpeas showed two odd dirs in /, of which /incidents contained a pcap file.
6. Copying the pcap file into the website so I could easily download it, I went through with wireshark until found a possible password for the lennie user. Ironically I got a little confused as the actions in the pcap file were very similar to what I was doing, for example /files/ftp/shell.php. thought it might be a live recording until i checked the dates
7. using the password i was able to ssh onto the box as lennie
8. under lennie's home dir was a scripts folder containing a script owned and only editable by root called planner.sh, but which invoked a /etc/print.sh owned by lennie to echo done
9. I set up a listener on my host, appended a reverse shell connect to the print.sh file, and waited. in about a minute I got a root shell (possible invoked by a docker host, as it wasn't in cron)

Easy, nothing special. I used linpeas to find the odd root dirs, which was possibly overkill. As mentioned, the room asked for user/root flags, but also the secret ingredient in the recipe, and this last was in /recipe.txt
