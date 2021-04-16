# KotH Hackers

https://tryhackme.com/room/kothhackers

Box is themed after the Hackers movie, nice. This room has nine flags, but the THM page won't accept them so I'm just tracking them and how they were found here.

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
