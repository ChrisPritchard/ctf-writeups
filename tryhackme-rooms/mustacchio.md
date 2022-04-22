# Mustacchio

https://tryhackme.com/room/mustacchio

A pretty easy room, as it says on the tin.

1. A full scan reveals 22, 80 and 8765. On 80 and 8765 are websites, with a mock website on 80 and an 'admin login' on 8765
2. Enumerating the mock site on 80, there are a number of folders for CSS, JS etc that are directory listable. Under the js file was 'users.bak'
3. Opening the file showed binary, starting with 'SQLite', showing this was a database file. Opening it with the SQLite CLI, its one table contained a user name of 'admin' with a password hash, which I looked up on crack station to get the password.
4. These creds got me through the admin portal, at which point there was an 'add a comment' form. Entering a comment and viewing the request, showed a post with a single form paramter, 'xml='. Playing around, I was able to get a comment to in the 'preview' fields by submitting '<comment><name>test</name></author>test2</author></comment>'
5. There was also a comment in the source that said 'barry you should be able to ssh in' or something to that effect. Given I had xml, obviously I needed to use XXE to retrieve Barry's private key. The payload to do this was: `xml=<!DOCTYPE+foo+[+<!ENTITY+xxe+SYSTEM+"file%3a///home/barry/.ssh/id_rsa">+]><comment><name>%26xxe%3b</name><author>test2</author></comment>`
6. The key was protected with a passcode, so I used ssh2john.py to get a version I could crack with john and rockyou, which quickly returned the code.
7. SSH'ing in I got john's user.txt flag
8. Next, I ran `find / -perm -u=s 2>/dev/null` to find SUID binaries, which returned `/home/joe/live_log` owned by root. Running this appeared to list the last set of requests to the webserver, i.e. that it used tail.
9. To confirm this, I extracted the binary back to my host and opened it with ghidra:

```c
void main(void)
{
  setuid(0);
  setgid(0);
  printf("Live Nginx Log Reader");
  system("tail -f /var/log/nginx/access.log");
  return;
}
```

10. Given tail is not run with a full path, this is a simple path exploit; I ran `export /bin/sh > tail && chmod +x tail` and `export PATH=/home/barry:$PATH` then ran live_log to get a root shell :)
