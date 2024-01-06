# Dodge

https://tryhackme.com/room/dodge, rated Medium

1. Scan reveals 22, 80 and 443. In particular, the cert on the 443 site reveals several hostnames to try in order to gain access to a site:
  
    `Subject Alternative Name: DNS:dodge.thm, DNS:www.dodge.thm, DNS:blog.dodge.thm, DNS:dev.dodge.thm, DNS:touch-me-not.dodge.thm, DNS:netops-dev.dodge.thm, DNS:ball.dodge.thm`

2. Enumerating these will find two that return a site: `dodge.thm` and `netops-dev.dodge.thm`. On the first is an uninteresting, unfinished site while the second shows a blank page (note, use https).

3. Looking into the page with more detail, you might notice that there is a file upload form on the page that is hidden with `display:none` - experimenting with this is a dead end however (later determined to the code not having the rights to put files in the upload folder)

4. There is a firewall.js file referenced that contains another URL - this page is more interesting in that it contains the output from the `ufw` (uncomplicated file), with a field that asks for a 'sudo command'. Notable under the output of ufw is that port 21 (ftp) is disabled.

5. Trying commands, only certain sudo commands are permitted specifically those related to the firewall. `sudo ufw allow 21` will open access to the FTP service.

6. FTP is accessible with anonymous access. Once in, it will appear to be in the home directory a user. While most files are inaccessible, there is a .ssh folder that contains not only an authorized_keys file but a id_rsa_backup file. The former provides the username of the user, 'challenger', while the latter is a copy of their private key and so you can ssh in with `ssh -i id_rsa_backup challenger@[remoteip]`.

7. Enumerating the system, there is a few websites defined under `/var/www`. One named notes does not seem publically accessible: running netstat -tulpn you can find local listening ports like 10000, and accessing localhost:10000 brings you to the notes login page.

8. To expose the notes site, exiting the ssh session and then reconnecting with local port forwarding helps: `ssh -i id_rsa_backup -L 0.0.0.0:10000:127.0.0.1:10000 challenger@10.10.182.166`. You should then be able to browse it externally via your attack box IP address

9. To login, view the source of the login page where you can see some commented out code containing credentials (redacted below):

   ```
   <form id="loginForm" class="mt-5">
        <div class="form-group">
            <label for="username">Username:</label>
            <!-- <input type="text" id="username" name="username" class="form-control" value="[redacted]"> -->
            <input type="text" id="username" name="username" class="form-control">
        </div>
        <div class="form-group">
            <label for="password">Password:</label>
            <!-- <input type="password" id="password" name="password" class="form-control" value="[redacted]"> -->
            <input type="password" id="password" name="password" class="form-control">
        </div>
        <input type="button" value="Login" onclick="login()" class="btn btn-primary">
    </form>
   ```

10. Once logged in, you can navigate to a dashboard which contains existing notes, including the password for the user 'cobra' which you can then su to.

11. Running `sudo -l` for cobra will reveal they can run `apt` as root. A trivial privesc to root is therefore running `sudo apt update -o APT::Update::Pre-Invoke::=/bin/sh` to get a root shell
