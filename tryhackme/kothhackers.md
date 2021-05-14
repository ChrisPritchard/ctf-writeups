# KotH Hackers

https://tryhackme.com/room/kothhackers

Box is themed after the Hackers movie, nice. This room has nine flags, but the THM page won't accept them so I'm just tracking them and how they were found here. Normally I would not put any flags in my writeups.

Port scan:

Open 10.10.89.242:21
Open 10.10.89.242:22
Open 10.10.89.242:80
Open 10.10.89.242:9999

9999 is the KOTH port and can be ignored.

## Flag 1: FTP

ftp allowed anonymous access, and the flag was in the file `.flag`: `thm{678d0231fb4e2150afc1c4e336fcf44d}`
also under ftp was a `note` file containing:

```
Note:
Any users with passwords in this list:
love
sex
god
secret
will be subject to an immediate disciplinary hearing.
Any users with other weak passwords will be complained at, loudly.
These users are:
rcampbell:Robert M. Campbell:Weak password
gcrawford:Gerard B. Crawford:Exposing crypto keys, weak password
Exposing the company's cryptographic keys is a disciplinary offense.
Eugene Belford, CSO
```

## Flag 2: CSS flag

On the website, in the css file, is the second flag: `thm{b63670f7192689782a45d8044c63197f}`

## Flag 3: FTP and gcrawford's home folder

The weak users from the anonymous ftp note can be brute forced against ftp. Specifically, gcrawford, after a long time with rockyou, will resolve a password. I had to get this from the official walkthrough, as the bruteforce took ages (longer than I'd normally bother in a ctf context). Also note the password for me was different than the one in the walk through.

This gives the users home folder, where you can retrieve a private ssh key, and the third flag: `thm{d8deb5f0526ec81f784ce68e641cde40}` from a business.txt file.

The key is encrypted, but can be easily broken with ssh2john and john the ripper.

## Root flag 4

gcrawford can, via sudo (accessed with their ftp password), run nano. The gtfobins entry on nano is sufficient to get to root.

.flag under /root was: `thm{b94f8d2e715973f8bc75fe099c8492c4}`

## Flag 5, 6 and 7: rcampbell, production and tryhackme home folders

Each contained a .flag file:

- rcampbell: `thm{12361ad240fec43005844016092f1e05}`
- production: `thm{879f3238fb0a4bf1c23fd82032d237ff}`
- tryhackme: `thm{3ce2fe64055d3b543360c3fc880194f8}`

cant find the last two flags, hmm
