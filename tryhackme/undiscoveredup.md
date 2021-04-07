# Undiscovered

https://tryhackme.com/room/undiscoveredup

A medium-classified room, but one with a few twists and turns :) Took me a sleep and *almost* giving up before I got it, but there is nothing here but the basics so its a great room.

The room description suggested adding 'undiscovered.thm to your hosts', which is generally a hint subdomain enumeration is required.

1. Enumeration revealed four ports: 22, 80, 111 and 2049. The latter two were not resolved, but these are NFS ports meaning I eventually would be able to mount something remotely, presumably.
2. On 80 was a simple website with a message saying 'follow the darker path, or similar'. A quick whack at it with Nikto and gobuster showed nothing, so I moved onto subdomain enumeration.
3. To enumerate domains, I used ffuf with `ffuf -u undiscovered.thm -H "Host: FUZZ.undiscovered.thm" -w directory-list-2.3-medium.txt" -ac`. This immediately revealed a bunch of entries, which was a bit suspicious. Going to one at random I found 'RiteCMS' running. Exciting! There is a public exploit for this and its stated version here: https://www.exploit-db.com/exploits/48636 HOWEVER, I quickly discovered the page was just a stub. All its links went nowhere.
4. Thinking through, I reran ffuf with the cms sub directory stated in the exploit: `-u undiscovered.thm/cms/` (note the trailing slash) and found one of the sites was real, the others all fake :)
5. On that site, the default credentials didn't work, so I broke it with hydra: `hydra -l admin -P ./rockyou.txt <redacted> http-post-form "/cms/index.php:username=^USER^&userpw=^PASS^:login_failed"` which quickly got me the admin password.
