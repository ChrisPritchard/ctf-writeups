# Git and Crumpets

https://tryhackme.com/room/gitandcrumpets

A relatively easy room, heavily Git focused as expected.

1. A scan revealed 22 and 80. Going to 80 would result in a redirect to YouTube - by using Curl or Burp's proxy logs, I could see the page doing the redirect referenced a hostname, `git.git-and-crumpets.thm`.
2. Setting up that hostname under hosts and browsing there revealed a 'Gitea' instance, an opensource github/gitlab-like tool. By registering an account I was able to browse two repositories, one by the user `scone` and one by the user `hydra`.
3. Neither repo contained anything in their contents or history that was useful, but the scone repo did have a comment on one of the commits saying they had put their password in their avatar image.
4. Downloading the image running exiftool against it, said their 'Password' was easy to guess. I tried `scone:Password` against Gitea and was able to log in.
5. Gitea has an authenticated remote code execution vulnerability, with a POC for this here: https://www.exploit-db.com/exploits/49571. I was able to use this with scone's creds to get a reverse shell as Git on the box.
6. This got me the user flag from `/home/git`, and also allowed me to add my public key to authorized keys in order to get a proper shell.
7. Enumerating, the box was running selinux so my options were limited. However, browsing around, I eventually discovered a third repository under gitea: `backup.git` by root.
8. Using  `git branch -l`, `git log <branch>`, and `git show <branch/commit>` I discovered that this had two branches, and that under the `dotfiles` branch, there was a commit that contained the root user's private key.
9. The private key had a passphrase, but the commit was for a file called `./ssh/Sup3rS3cur3`, so I tried 'Sup3rS3cur3' and this worked to get me a root shell :)

Overall, not too difficult. I stumbled upon the root repo by accident, after trying the standard approaches and trying (and failing) to get linpeas on the box - selinux blocked usage of common tools which made getting files on here tricky. I was actually trying to find where gitea was so I could enumerate its config when the `find / -name gitea` found the repo.
