# Convert My Video

"My Script to convert videos to MP3 is super secure"

1. Recon showed just 22 and 80, the latter being the titular website: A single page that lets you insert a youtube id and download a video mp3 (not that this worked, given the vm doesnt have internet access).

2. dirb and nikto revealed a subdirectory, `/admin`, protected with basic auth. Nothing else showed up.

3. The javascript for the page posted to itself with the constructed youtube url. By deforming this I discovered the server was using `youtube-dl`, a python tool, and the url was being placed on the command line. I confirmed that this was an injection vector via `$(ls)` , which worked...sortof, placing the first part of ls (the name admin for the subfolder) in the output error message but nothing else.

4. The site would give in its error something saying --restrict-filenames was turned on. This meant no spaces, either in the request or the response. I played around with a number of techniques:

    - piping commands, e.g. `ls|base64` is valid bash and results in ls emitted as a single base 64 string. However I needed args to be useful.
    - brace expansion (eg. `{ls,"admin"}`) didn't work in the tool, unfortunately
    - likewise param injection didn't work. e.g. this failed in the tool: `CMD=$'\x20a\x20b\x20c';echo$CMD`
    - IFS failed too: no `echo${IFS}test`

5. Finally I found a solution with `xargs`: this grabbed a specific file for me: `xargs<".htaccess"|cat|base64`

    `PEZpbGVzIC9hZG1pbi8uaHRwYXNzd2Q+IE9yZGVyIGFsbG93LGRlbnkgRGVueSBmcm9tIGFsbCA8`

    Which decodes to:

    `<Files /admin/.htpasswd> Order allow,deny Deny from all <`

6. From that I grabbed the mentioned file: `itsmeadmin:$apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y/`

7. Hashcat cracked that password via: `hashcat64.exe -m 1600 $apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y/ ../wordlists/rockyou.txt` (in 9 milliseconds :D):

    `$apr1$tbcm2uwv$UP1ylvgp4.zLKxWj8mc6y/:jessie`

8. Getting through the admin portal revealed a page that took arbitary (with spaces, thank the gods) commands in the query string: basically a full web shell. `whoami` gave `www-data`