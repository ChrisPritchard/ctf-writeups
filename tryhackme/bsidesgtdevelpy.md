# Develpy

A 'medium' room for the bsides set, but overall pretty easy.

1. Recon revealed 22 and 10000. The latter when browsed through a python error. Ultimately I determined I could reach it better using netcat, where it prompts for a number and runs ping like scan results using that.

2. The error suggested unsanitised input. In the error it reflects the bad result value back in the message. Through this I tried entering: `__import__('os').popen('ls').read()` and successfully got a list of files in the error message. Great, rce.

3. Using the above to invoke `whereis nc` showed it was running the nc that supports `-e`, so I set up a listener and used the injection to get a reverse shell. The user flag was in the home directory of `king`.

4. Also in this dir were `run.sh` and `root.sh`. Both were being run every minute by a cronjob, with the former by king and the latter by root. I checked and I could delete/rename root.sh, even though I didn't own it.

5. `echo "cat /root/root.txt > root.txt" > root.sh` created a script that got me the final flag pretty promptly.