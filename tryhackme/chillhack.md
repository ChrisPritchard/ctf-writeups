# Chill Hack

This room provides the real world pentesting challenges. (<- this claim is disputed)

Quite interesting, if simple, until I ran into stego.

1. nmap found 21, 22 and 80
2. while ftp granted anonymous acces, the text file within wasn't useful (sort of implied something later, but wasn't really a hint)
3. dirb on the site found /secret, which appeared to show a webshell that would filter certain commands
4. while `ls` was blocked, `dir` showed index.php. `cat` was blocked, but `nl index.php | base64` was not, which gave me the block list
5. while i couldn't use shells like sh or tools like nc, i was able to use a base64 reverse shell one liner, and emit it to echo `b64 | base64 -d > /tmp/test`
6. `chmod +x /tmp/test && /tmp/test` connected me with a www-data reverse shell
7. sudo -l revealed a script under amaar's directory called .helpline.sh that I could run as amaar. The script basically executed whatever you gave it in an interactive prompt. `sudo -u amaar /home/amaar/.helpline.sh` got me an amaar shell.
8. at this point the shell was getting a bit messy, so i added my public key to amaar's authorized keys and ssh'd in properly
9. bouncing around I found a /var/www/files website that looked interesting, and a mysql password, but i got nowhere here

I found at at this point it was a stego challenge with an image in that dir, ugh.

10. steghide with no passphrase revealed backup.zip from the image from the files site above
11. zip2john and john with rockyou revealed the passphrase for teh zip was pass1word
12. inside was a php file containing a base64 encoded password for the user anurodh
13. anurodh was a member of the docker group, so using gtfo-bins I ran `docker run -v /:/mnt --rm -it alpine chroot /mnt sh` to get a root shell

Overall, different and interesting. But I really hate stego - don't do this please people. Its just a guessing game with stego.
