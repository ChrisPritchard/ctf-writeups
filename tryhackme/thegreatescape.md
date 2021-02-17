# The Great Escape

https://tryhackme.com/room/thegreatescape

"Our devs have created an awesome new site. Can you break out of the sandbox?"

Really fun room, though it took me a while. Purposefully designed to render some of the common brute forcing tools useless, and used a whole combination of techniques to get root :)

## First steps with Recon

1. enumeration revealed 22 and 80. version scanning took a *while*, which later was discovered because that 22 port is running endlessh, a ssh tarpit.
2. on 80 was a photo website, abd basic enumeration revealed:
  - it had two links, courses and admin, both of which redirected to a login page. there was a signup link that was disabled. 
  - requests to login went via a /api/login method. /api/ had nothing to see here.
  - there were numerous webpacked javascript files: i found the message 'if you can see this, im sorry mario you are in the wrong castle'. basically a hint to stop crawling the js.
3. basic web dirb/gobuster returned nothing - also, this was tricky as every request returned a 200 as the spa loaded its 404 page. i also later (much later /sigh) discovered that there was rate limiting, which returned 503 to requests if they were too quick. this rendered ffuf, gobuster, burp intruder useless.
4. the first hint said, 'well known'. i thought this might be robots, and there was a robots, but that was not for this. i eventually just tried (not sure why it took too long, maybe because it was too obvious) `.well-known/security.txt`, and in there found a api url that **got me the first, web flag**.

## Getting the flag via backups

so, robots. its content was:

  ```
  User-agent: *
  Allow: /
  Disallow: /api/
  # Disallow: /exif-util
  Disallow: /*.bak.txt$
  ```
  
1. on exif-util i found a page that allowed uploading images or fetching them from a url. a proper image would render the exif data for that image. i went down a rabbit hole with this, trying a XXE exploit by putting valid XMP-xml in the XMP tags of a jpg. to do this i used a tool like https://github.com/BuffaloWill/oxml_xxe, but I was unsuccessful.
2. when fetching from a url, I found I could fetch from the site itself. importantly, if the url was NOT an image, it returned the content verbatim. So... SSRF. However I couldn't use it to fetch anything but a url.
3. This was where I got to after the first hour. Many hours later (took me a while to discover ffuf was ruined by 503s), and obsessed with that .bak.txt rule plus the statement that devs leave their backups around (which was the hint), I eventually tried /exif-util.bak.txt

Damnit. Soo easy it was hard to find :D

4. The result was what was probably the vue template for an older version of the tool. In there was one important line: the url it used: `const response = await this.$axios.$get('http://api-dev-backup:8080/exif' ... etc ...`
5. 8080 is not exposed on the machine, but i didn't try that anyway. Instead I used this with the SSRF from before, and sure enough I got a response! Here is the request (using the API that the exif-util used: `GET /api/exif?url=http://api-dev-backup:8080/exif`.
6. playing around with this I eventually discovered that passing a malformed or blank url gave a very important message: this `GET /api/exif?url=http://api-dev-backup:8080/exif?url=` returned an error saying something like 'curl needs a url passed to it'. This immediately said 'os injection' and sure enough, I eventually got the golden text proving this when I used the url: `GET /api/exif?url=http://api-dev-backup:8080/exif?url=;id`. This would error curl as before and then print the id result out.

Exploring with the RCE I found out several things:

- bash and nc was blocked, making getting a reverse bind difficult.
- | and > would also cause issues
- there was no wget on the server, so downloading a shell would use curl
- but this was irrelevant anyway since with curl I was able to prove the machine couldn't reach my attack machine

Aside from this, the shell was actually pretty robust. `ls -laR /root` for example worked fine, as long as the spaces were encoded.

7. speaking of, this revealed 'dev-note.txt' in the root folder. The message was (password redacted):

  ```
  Hey guys,

  Apparently leaving the flag and docker access on the server is a bad idea, or so the security guys tell me. I've deleted the stuff.

  Anyways, the password is [redacted]

  Cheers,

  Hydra
  ```
  
  I tried this password on ssh and it froze (again, tarpit there), but the important thing was the first line: flag deleted etc.
  
8. the other thing that jumped out from `/root` was the presence of a `.git` folder. 'deleted' and git was pretty obvious :)

> Here I did something a bit silly, but interesting enough to document. 
> 
> I figured i needed to pull the .git folder back to my host so I could explore it, but how?
> 
> `tar -cf gitar /root/.git` would create a file, and then I tried using `base64 /root/gitar` but it was too large, and timed out the request
> 
> Instead I repeated these steps, but focused on the objects subdirectory of .git, which actually contains the commits
> 
> This worked and I got the tar back to my machine as base64. to hydrate it, I created a new git repo via git init, copied objects inside, and then could use git log / git checkout as normal (albeit with some warnings about dangling commits).
> 
> Ultimately silly though, it was far easier just to do this on the remote machine

9. git can be targetted to a given folder via `--git-dir`. so, with this, i used url to get the git history: `http://api-dev-backup:8080/exif?url=;git+--git-dir+/root/.git+log`
10. from that I saw a commit where the 'insecure' files were added, and I checked out that commit: `http://api-dev-backup:8080/exif?url=;git+--git-dir+/root/.git+checkout+[redacted]`
11. this **got me the next flag**

## Final escape

The checkout also got me a new dev note:

  ```
  Hey guys,

  I got tired of losing the ssh key all the time so I setup a way to open up the docker for remote admin.

  Just knock on ports [redacted] to open the docker tcp port.

  Cheers,

  Hydra
  ```

Hmm. The knocking was easy: `knock [host] [ports seperated by spaces] -d 500` would unlock the port, which I confirmed with nmap/rustscan. This port was 2375, the 'docker' port.

I've never done remote management with docker before (used docker aplenty of course), but a quick primer showed it was easy, not too dissimilar to that git dir stuff. This command confirmed I was golden: `docker -H tcp://10.10.55.209:2375 container list`.

Boom! It showed the running containers, including identifying that bastard endlessh!

Next step, what images do I have? `docker -H tcp://10.10.55.209:2375 images` which showed the ever handy `alpine` was available.

The final exploit was `docker -H tcp://10.10.55.209:2375 run -it --rm -v /root:/mnt/root [alpine id on box]`: this got me a shell in a container where /mnt/root was the root folder on the host, where **I found the final flag**.

## Summary

Overall, probably one of the more fun rooms in recent times for me. SSRF into OS Command Injection into Git history crawling was special, port knocking and docker remote management plus a container escape was also cool. And even the initial enumeration, as frustrating as it was, *felt* more logical/puzzle-like than the normal dumb enumeration. All props to the creator.
