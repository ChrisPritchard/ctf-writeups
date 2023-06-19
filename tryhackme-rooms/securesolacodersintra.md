# Intranet

https://tryhackme.com/room/securesolacodersintra

*Welcome to the intranet!*, a room by [toxicat0r](https://tryhackme.com/p/toxicat0r), rated Medium

> The web application development company SecureSolaCoders has created their own intranet page. The developers are still very young and inexperienced, but they ensured their boss (Magnus) that the web application was secured appropriately. The developers said, "Don't worry, Magnus. We have learnt from our previous mistakes. It won't happen again". However, Magnus was not convinced, as they had introduced many strange vulnerabilities in their customers' applications earlier.
> 
> Magnus hired you as a third-party to conduct a penetration test of their web application. Can you successfully exploit the app and achieve root access?

A fun room, with *seven* flags, each representing a different stage of the compromise. Took me a day to get the first flag, a little while to get the third, but otherwise it was smooth sailing. I would say its a room with 'simple solutions that are hard to find'.

1. Initial recon revealed ports 7, 21, 22, 23, 80 and 8080. 7 was just an echo service, 21 and 23 required credentials that I never obtained; at a guess, these were all rabbit holes. On port 80 was a simple 'under contruction' page, with no discernable functionality, while 8080 redirected to a /login page. The login page indicated that the username was in the format 'user@securesolacoders.no', and in the source of the page the usernames 'devops' and 'anders' were revealed in a comment.

2. The hint for the first flag was that it was that a custom wordlist might be required; I spent a day or so with various bruteforcing techniques (eventually discovering a third user, 'admin', as the login form allows username enumeration) with no success. I can't really give a hint without giving the  password away here, but will just say I guessed it, and it was pretty basic.

3. On the next screen was the first flag, and a form asking for an SMS token, in the format 0000 to 9999, sent to some imaginary mobile number. This form did not perform any rate limiting, and the SMS token is set once per login. I brute forced it with Burp Suite's Intruder, as I own the professional edition, but it could have also been done with something like FFuf from the attack box, likely faster.

4. Past that is the second flag and the home page of the Intranet. It had four apparent pages: Home, Internal, External and Admin, with the last blocking on unauthorised. Brute forcing the sub directories found a few more rabbit holes, like temporary and application. Of the three accessible pages, the only significant functionality was a form on Internal, that made a POST with the payload 'news=latest'.

5. This took a while for me to realise this was local file inclusion, of a sorts, which can be confirmed with changing latest to `../../../../etc/passwd`. The hint suggested I should be searching for the source code of the site, which by this point (based on response headers) I had guessed was a python-based flask application. Accessing `../../../proc/self/environ` revealed that the PWD environment variable was `/home/devops`, suggesting that the source code was in there somewhere. I experimented with several candidates until I guessed the name for the site's source file and loaded it up.

6. The third flag was in this source file. The source code revealed the site's structure, including showing some of the rabbit holes. Notably it also showed that /admin could only be accessed if the username was 'admin', and that this would provide a means to get code execution:

  ```python
  @app.route("/admin", methods=["GET", "POST"])
  def admin():
        if not session.get("logged_in"):
                return redirect("/login")
        else:
                if session.get("username") == "admin":

                        if request.method == "POST":
                                os.system(request.form["debug"])
                                return render_template("admin.html")

                        current_ip = request.remote_addr
                        current_time = strftime("%Y-%m-%d %H:%M:%S", gmtime())

                        return render_template("admin.html", current_ip=current_ip, current_time=current_time)
                else:
                        return abort(403)
  ```
  
  However, it was impossible to login as admin:
  
  ```python
  if username.lower() == "admin@securesolacoders.no":
      error = "Invalid password"
      return render_template("login.html", error=error)
  ```
  
  But, the session key used for the flask cookie was potentially very weak:

  ```python
  key = "secret_key_"   str(random.randrange(100000,999999))
  app.secret_key = str(key).encode()
  ```
  
  And a quick look at the key revealed its format was:

  ```
  {'logged_in': True, 'username': 'anders'}
  ```

  So if I could brute force the key to resign a cookie changing my username, I could proceed.
  
7. I did this with a tool named [flask-unsign](https://pypi.org/project/flask-unsign/) over several steps:

  a. First I generated a wordlist with bash: `for i in {100000..999999}; do echo secret_key_$i >> wordlist.txt; done`
  b. Next I bruted out the secret key with `flask-unsign -c [session_key] -u --wordlist=wordlist.txt`
  c. Finally I created a new key with `flask-unsign -c "{'logged_in': True, 'username': 'admin'}" -s -S [discovered_secret]`
  
  This allowed me access to the admin section.
  
8. The fourth and final web flag was on the admin page. As shown in the code above, any payload passed as 'debug=[command]' in a POST request would be executed, but not reflected. I used a simple openbsd netcat payload to get a rev shell.

9. The user.txt flag was in devops home directory. To get a stronger shell I added my SSH public key to a new authorized_keys file under .ssh for devops, then ssh'd in directly.

10. The next target was user2.txt, presumably by laterally moving from the devops user to anders. This proved to be fairly simple: a look at the output of `ps aux` showed that the port 80 website, the 'under contruction' page initially discovered, was being run via Apache out of /var/www/html, and Apache was running under ander's user account rather than something generic like www-data. This meant any code execution in the port 80 website would be as anders. Under /var/www/html there was just an index.html page, but devops had the ability to write files to that directly. Therefore, I created a webshell in PHP and dropped it in there, giving me code execution as anders. Anders already had a authorized_keys file, so I added my public key again and logged in directly over SSH as anders.

11. The user2.txt file was in ander's home directory, leaving just root.txt to go. A quick enumeration revealed that anders could restart the apache service as root (seen by running sudo -l). The way apache works is that it is started by root, and then switches to the relevant user its to run as. I figured since Anders was the relevant user, I might be able to write something that root would execute. Enumerating /etc/apache2 I found a writable file that appeared to be a bash script, and added `cp /bin/sh /sh && chmod u+s /sh` to it. After restarting apache I had a suid-bit set root owned sh binary in root.

12. `/sh -p` got me an effective root shell and the final flag.

Fun room, overall, quite a few techniques on display. 
