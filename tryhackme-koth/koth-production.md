# Production KOTH machine

## path to foothold

- ftp and smb (under /key) contain the .ssh directory of teh `ashu` user, with a private key.
- on port 9001 there is a 'backdoor', which if your submit 'yourmom!' will give a shell as user `skidy`

## path to root

- `ashu` can switch to skidy via `sudo /bin/su skidy`
- `skidy` is able to run git as root, and set environment variables. escalate to root with `sudo PAGER='sh -c "exec sh 0<&1"' /usr/bin/git -p help config`

- `/bin/less`, `/usr/bin/expand` and `/usr/bin/git` have the suid bit set that allows you to read any file

## overly limited shell

Additionally, on port 9002 is a 'overly limited shell' running as root. this only allows 12 character or less commands, and doesnt permit stream redirection.

its possible using printf or echo you could make a script call to something else, or exploit a binary you otherwise put somewhere, e.g. copying a client into the run dir to skip the other privesc methods

## flags

- /home/ashu/flag.txt
- /home/ashu/mail-server-backup/support-room-help.txt
- /home/skidy/flag.txt
- /var/ftp/flag.txt

## ssh keys

Ashu's id_rsa:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2Q0d+88kD5UvObCopl0rAVPfTHsLjUIDcz+f+lGt1wXHunJH
Ch5Vd+SJP/3yoH+KhR3Y2SN5dWWdhEz8TPCd5+QGCsoRilp+UD2csoO5e8qHbaPj
sFBBxGnOLJBFleYGg/ZKW3E5Sd+uhzExKjyBzGXp4rClAJ8XWHnvIljb3TEM8oxf
EvhJ8+rVOGflvvZQZODgWtAQ/BHxoHklaMTawLdKvcdMIQpxNzHXdcazrhP+jGT0
kwLgKITeLs35UBlQygd8OHJzVx5KZi8AM9DKqm7ZF7LUsDxzL1++wmNvJJLLtRSI
jXI8Bit1j1coDoVmr0S9SeaUMLC4R3jUPC9EmwIDAQABAoIBAQCdIDzLdInDahkU
50k/ngSq4l+tSwnyyY4b2TxjhsuU9E9BLsc0kP8IWv3swFbrT0kk0pWPo3mivdwI
0X536Fw3ab/iAaQvBxGX3vJX3Lni3pupiFIk6gSiPoINiqeFO08OKrZregyh6Pa8
UaUo0UKZiFGHVJ8uUv0ghKzTrYYEmc8KItEiNncRWdGDMLb2HpL0xOzbA5fUgrRa
tJNOaws5uzPg5KjmoAVF2EVE9+NVaYQBpbISjvaYaIxx271vhO8Hk0uSRaVFXxfj
muy/or1B8W6EFe3Uzj1oc5Nb+hwXvTqkNUEt2Lp7AN7edLQihmLhBDV7+ux6Bkb3
7ed7gkiJAoGBAPZPXDsqhCwXhRUbbYMANZOix7P51BlyBXy6OptwBQfXjfbTrpEF
dbmaaaTkUs1Dc2UMrb2BEm6jwi290SghA+h32bNQ+m3osyVyzz0tdlobO09ATnde
Ww00letoaaWCsN9xc/Bdi1fW0/9jCNPcMRdDnTLooxpycktunle56uhPAoGBAOGX
FfEEx3HcU/MvkN377ePmB9UyY0dUHmCXnAjUmZcQxrPnB1+MOMa2BXZnnfneBqJ+
OP08JAiETnS0vPRZEUgzmoiwd31OwM26Dy6k3K6pvuRJFRDs6TzOCNMGVKIpa+7b
dYb+vWv1kLlfWTsdcFWpVcdHEGUhglEqLS61NL/1AoGAPQzmm3OqVxNtVRH7TuEa
ZoGOZjmiLLxqR8QRCr31QUBYW7mUJzXnPB3d2ZUOQPpa+8zss2/ulaXZV2UZFo04
XsJ2H1APAncPEFUosM037JWbWcVirYuhneBO2I6EwRVnqbqBNi65fwgse7ycT4bg
VBfaOugWpVOAqNm+PZhDdVkCgYEAw8qNkJHFSF0hv38ZDJEK9zE+uxrwb4filZMA
KenbI/G7g4iQLa1V2aFBPHLR+Xtp5r4GWENKQtoR/dif5rMm/LNM/DWsf2VKkUNa
yfDsV+ubcia70eTMyalIn15vNg8dTkHKz09ot7p50Wmf2F7EkJRXjo1u/VcH88nX
TSKYlcECgYB37GE0Ok+ku9FF5JdUvXSU0ONYXWe642BLM1nilYa6WUY82e3T6lCL
wQBUqNrTiki6LPi/f99Zhzx9M1j/3mQEgDqDgcIUFVqC+wQpYp9qcrhsuAjUE0pF
M0RJ2j6JlVlGH3IHMDcC4/6M1yMGfct/fajrVzQHHY7qIzHk3tZCQw==
-----END RSA PRIVATE KEY-----
```
