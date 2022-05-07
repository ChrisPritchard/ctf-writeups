# Leviathan 0

Username: leviathan0
Password: leviathan0

1. Access with SSH using the given credentials.
2. Nothing is in the home folder at first glance...`ls -A` to see a `.backups` folder.
3. In backups is booksmarks.html, a large html file. `cat bookmarks.html | grep leviathan` to find the password for leviathan1.

I also initially copied the bookmarks file locally using scp: `scp -P 2223 leviathan0@leviathan.labs.overthewire.org:/home/leviathan0/.backup/bookmarks.html .` - this command is useful and has been used later in the challenges when I need a local copy of a binary.
