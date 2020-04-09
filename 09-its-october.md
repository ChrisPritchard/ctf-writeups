# It's October

https://www.vulnhub.com/entry/its-october-1,460/

## Recon

Nmap revealed:

```
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
3306/tcp open  mysql
8080/tcp open  http-proxy
```

The mysql service didn't allow login remotely. Port 80 showed a brochureware site, with nothing much on it.

Port 8080 revealed a site called 'my notes', with a full screen jpeg containing no information. A look at the source revealed a commented out `mynote.txt` which when browsed to, revealed:

```
user 		- admin
password 	- adminadmin2 
```

This didn't work via the ssh connection (which is wired to use ssh certs only, not username/password). However, a quick `dirb` on the port 80 website revealed a `/backend`, which provided a login screen for something called OctoberCMS. The creds worked here :)

## October CMS

Once inside, I browsed around. There were asset links that allowed uploading files, but restricted extensions to a safe whitelist. I found the version from `/backend/system/updates`, and a search showed that while prior versions had an upload filter bypass, the current version did not.

Checking the logs I saw a couple of old errors that looked like this:

`ErrorException: Use of undefined constant hi - assumed 'hi' (this will throw an Error in a future version of PHP) in /var/www/html/octobercms/plugins/rv/phpconsole/controllers/ScriptsController.php(41) : eval()'d code:1`

phpconsole sounded interesting...I did a search and its an OctoberCMS plugin. It didn't seem to be installed, however the interface allowed me to search for and install it, easy peasy!

The interface permitted me to execute arbitary php code, including system. `system("whoami");` revealed www-data. I tried a few ways to get a reverse shell, but it appeared that the system could not call out via this interface.
