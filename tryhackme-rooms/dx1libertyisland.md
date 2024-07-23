# Deus Ex 1: Liberty Island Official Walkthrough

https://tryhackme.com/room/dx1libertyislandplde

"Can you help the NSF get a foothold in UNATCO's system?"

A boot2root inspired by the first level of Deux Ex (2000), where you assault Liberty Island which has been taken over by NSF terrorists (though with Deus Ex, nothing is as it seems). You take the role of a hacker trying to compromise UNATCOs network as part of the attack.

Most of the text from this room is taken directly from notes and emails encountered throughout that level and the UNATCO (united states anti-terrorist coalition) base that is on the island. I used https://nuwen.net/dx.html as a very good resource, which contains extracted text files from the game.

<details>
  <summary>Initial Enumeration</summary>

1. An initial scan with Rustscan or `nmap -p-` reveals three ports of note open:

  - 80, hosting what looks like a custom website
  - 5901, a VNC server. This will need a password
  - 23023, some sort of custom API.

2. Enumerating the API first, it responds with the following:

  ```
  UNATCO Liberty Island - Command/Control

  RESTRICTED: ANGEL/OA

  send a directive to process
  ```
  
  Trying `?directive=id` results in the same message, so I try to post with `curl -d 'directive=ls' 10.10.198.83:23023`. This responds with:

  ```
  UNATCO Liberty Island - Command/Control

  ACCESS DENIED - Invalid Clearance-Code
  ```
  
  So I need some sort of clearance code.
  
3. Enumerating the website on 80, it seems pretty static. Of note is the `/badactors.html`, which has an iframe containing a list of usernames from `badactors.txt`. There is also a note in the HTML, but this doesn't hint at anything other than that this page is special in some way.

4. Nikto reveals there is a robots.txt. Looking at the file, I see:

  ```
  # Disallow: /datacubes # why just block this? no corp should crawl our stuff - alex
  Disallow: *
  ```
  
  Going to `/datacubes` I am redirected to `/datacubes/0000/`, which says:
  
  ```
  Liberty Island Datapads Archive

  All credentials within *should* be [redacted] - alert the administrators immediately if any are found that are 'clear text'

  Access granted to personnel with clearance of Domination/5F or higher only.
  ```
  
  This suggests that I might find some more entries with different four number codes.

</details>

<details>
  <summary>Path to User</summary>
  
5. Using burp intruder (could also be done with ffuf and crunch, or you're favourite directory enum tool), I test all paths from 0001 to 9999. This finds five new pages, almost all of which contain what look like placeholders for credentials, subbed with [redacted]. One, however, is different:

  ```
  Brother,

  I've set up VNC on this machine under jacobson's account. We don't know his loyalty, but should assume hostile.
  Problem is he's good - no doubt he'll find it... a hasty defense, but since we won't be here long, it should work.

  The VNC login is the following message, 'smashthestate', hmac'ed with my username from the 'bad actors' list (lol).
  Use md5 for the hmac hashing algo. The first 8 characters of the final hash is the VNC password.

  - JL
  ```
  
6. There are two users on the badactors list which might match the initials 'JL' (If you know deus ex or check Nuwen's site in the thanks section you can find out the username as well). To create a hash, I can use the HMAC function of cyberchef, using the username as the key (UTF8), the algorithm as md5, and `smashthestate` as the input message. The same could be done with Go code like the following:

  ```go
  package main

  import (
    "crypto/hmac"
    "crypto/md5"
    "encoding/hex"
    "fmt"
  )

  var candidate = "[redacted]"

  func main() {
    mac := hmac.New(md5.New, []byte(candidate))
    mac.Write([]byte("smashthestate"))
    expectedMAC := mac.Sum(nil)
    fmt.Println(hex.EncodeToString(expectedMAC)[0:8])
  }
  ```

Creating the hashes, I found the correct one to be the one ending in `********830c1332a903920a59eb6d7a`. The first eight characters were the VNC password. After logging in over VNC (I used remmina which has a VNC function, but tigervnc viewer or tightvnc viewer work as well) the user flag is on the desktop.

</details>

<details>
  <summary>Path to Root</summary>

7. Also on the desktop was a 'badactors-list' binary. Running the binary pops a UI window, which after a moment loads the badactors list and allows me to edit it. The binary starts by saying its connecting to `UNATCO:23023`... the mysterious service from earlier. Presumably that means it has a clearance code.

8. The binary is written in Go, and so will be a pain to decompile or use strings on. Instead, if it really is making a HTTP request, then there are two approaches I can think of: I can edit hosts if writable, to point UNATCO at my own server. Or I can use a simple nc listener on the box if nc is available, then start the badactors-list binary with a proxy setting pointing at the listener. Hosts is unfortunately not writable for the alex user, but nc is indeed available (along with other net tools).

9. Using the nc approach, after setting up a listener I run the badactors list via `HTTP_PROXY=localhost:4444 ./badactors-list`. After a moment I capture a full request, complete with clearance code and a suggestion that the directive argument is straight command execution, as it is running `cat /var/www/html/badactors.txt`

10. I set this clearance code as a header named 'Clearance-Code', `curl -H 'Clearance-Code: [redacted]' -d 'directive=whoami' 10.10.198.83:23023`, then submit my http request from before. The result comes back as `root`, and I am able to get the final flag at `/root/root.txt` :)

</details>