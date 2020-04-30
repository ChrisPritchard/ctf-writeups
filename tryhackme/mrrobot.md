# Mr. Robot

## Recon

`nmap -p 10.10.156.16` reveals:

```
Starting Nmap 7.80 ( https://nmap.org ) at 2020-04-30 04:22 UTC
Nmap scan report for ip-10-10-156-16.eu-west-1.compute.internal (10.10.156.16)
Host is up (0.00040s latency).
Not shown: 65532 filtered ports
PORT    STATE  SERVICE
22/tcp  closed ssh
80/tcp  open   http
443/tcp open   https
MAC Address: 02:07:5E:78:45:78 (Unknown)
```

Both website addresses loaded a sort of qausi-terminal in the browser, something that looks like it was maybe copied from a promotional site for the show.

Nikto on the http site revealed:

```
- Nikto v2.1.6
---------------------------------------------------------------------------
+ Target IP:          10.10.156.16
+ Target Hostname:    10.10.156.16
+ Target Port:        80
+ Start Time:         2020-04-30 04:30:32 (GMT0)
---------------------------------------------------------------------------
+ Server: Apache
+ The X-XSS-Protection header is not defined. This header can hint to the user agent to protect against some forms of XSS
+ The X-Content-Type-Options header is not set. This could allow the user agent to render the content of the site in a different fashion to the MIME type
+ Retrieved x-powered-by header: PHP/5.5.29
+ No CGI Directories found (use '-C all' to force check all possible dirs)
+ Uncommon header 'tcn' found, with contents: list
+ Apache mod_negotiation is enabled with MultiViews, which allows attackers to easily brute force file names. See http://www.wisec.it/sectou.php?id=4698ebdc59d15. The following alternatives for 'index' were found: index.html, index.php
+ OSVDB-3092: /admin/: This might be interesting...
+ OSVDB-3092: /readme: This might be interesting...
+ Uncommon header 'link' found, with contents: <http://10.10.156.16/?p=23>; rel=shortlink
+ /wp-links-opml.php: This WordPress script reveals the installed version.
+ OSVDB-3092: /license.txt: License file found may identify site software.
+ /admin/index.html: Admin login page/section found.
+ Cookie wordpress_test_cookie created without the httponly flag
+ /wp-login/: Admin login page/section found.
+ /wordpress: A Wordpress installation was found.
+ /wp-admin/wp-login.php: Wordpress login found
+ /wordpresswp-admin/wp-login.php: Wordpress login found
+ /blog/wp-login.php: Wordpress login found
+ /wp-login.php: Wordpress login found
+ /wordpresswp-login.php: Wordpress login found
+ 7889 requests: 0 error(s) and 19 item(s) reported on remote host
+ End Time:           2020-04-30 04:35:33 (GMT0) (301 seconds)
---------------------------------------------------------------------------
+ 1 host(s) tested
```

`robots.txt` contained:

```
User-agent: *
fsocity.dic
key-1-of-3.txt
```

Giving me an easy first key of `073403c8a58a1f80d943455fb30724b9`

`fsocity.dic` (note the mispelled society) seemed to be a show-focused wordlist. Hmm...