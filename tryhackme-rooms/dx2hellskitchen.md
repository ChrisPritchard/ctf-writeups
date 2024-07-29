# DX2: Hell's Kitchen!

Second room in the Deus Ex (2000) inspired series. This one is considerably more tricky than the first room, but not crazily so: every step is trivial, but with a twist. The first room was [DX1: Liberty Island](https://github.com/ChrisPritchard/ctf-writeups/blob/master/tryhackme-rooms/dx1libertyisland.md)

## Website 1

1. Scanning will reveal just two ports: 80 and an unusual port. On both is a website, the first containing the apparent home page for the 'Ton Hotel, and the latter a login interface to NYCOMM mail.
2. With no creds efforts should be focused on the first site, which seems pretty basic. There is a guest book, an about page and a new booking page, however the button that opens new bookings is disabled by javascript as no bookings are available.
3. By examining the javascript code you can see it makes an api call, but this is a simple get request with no params and doesn't seem vulnerable. However you can learn the path to the new booking page.
4. By going there a message says no rooms are available, however the page is running javascript and there is a hidden form. The javascript grabs a cookie value and makes another API call, and then if that works populates two form fields (days and room num) with the results. This might be a path in.
5. The cookie value looks encoded, and the encoding isn't base64. However, reloading the page a few times will show that the latter half of whatever is encoded is changing, suggesting this is some form of encoding. Experimentation will find the correct one (its not too obscure), and reveal that the encoded value is the combination of a label and a key.
6. Creating your own encoded key and sending it to the API call will allow you to discover this is SQL Injection of some sort, through the usual methods of triggering an error.
7. At this point, SQLMap might be an option however the exploit will be difficult:

    - the aforementioned encoding is not supported natively by SQLMap, so it would need to be modified or its `--eval` attribute used or similar
    - the API call seems to take a minimum of a second to run, which makes SQLMap painful to use
    - the API call will happily return 404, 400 and 500 errors to most requests - in particular there is no valid booking ID to use as no rooms are available, meaning the default case is 404. SQLMap doesn't like that

8. A better option is to manually exploit this, but SQLMap is possible with effort. Eventually the database type can be discovered and then its content enumerated, which amongst other things will include email credentials.

## Website 2 & Web Flag

1. With the email credentials the second site on the unusual port can be accessed, which will land you in an email interface.
2. The interface is basic, just allowing you to click through various emails the user has received: in one of them you can find the **web flag**.
3. With no further functionality the site seems unexploitable, however there are two hints forward:

    - in the top left of the page, a very small piece of text shows the current time, incrementing each second.
    - if the javascript is examined (its minified, but most tools will undo that) some code that connects to a web socket is identified: this sends the user's local IANA timezone to the server and receives the date back, which it updates the top left with

4. With a tool capable of examining the web socket traffic, this can be looked into more closely. The date value that comes back may or may not match the users local time (depending on their timezone) but does look like the output of the `date` function on a unix machine. A way to set the result of that function to match a specific timezone is via something like `TZ=[timezone] date` - so this might be RCE.
5. Sending a simple payload like `; id ;` will confirm this, with the websocket returning data identifying the first user. However, further experimentation might uncover some limitations: 
    
    - the amount of characters is limited, presumably to the max for a IANA timezone value. Trial and error will discover the exact amount, which restricts what can be run.
    - the site's working directory is `/`, meaning files need to be saved to `/tmp` or otherwise, adding more characters
    - finally, getting a shell to connect back will be a struggle: why can be discovered via a note in the user's home directory, but essentually the only rev shell ports that can be used are `80` and `443`.

6. At this point there are a few options to get a foothold, with the bluntest being something like adding bits of a rev shell command (nc.openbsd) to a script one piece at a time, then running it. Or downloading from a remote server if the characters can be crammed in, but sooner or later this will grant access as the user **gilbert**.

## Foothold & User Flag

1. Gilbert has a few files in his home directory, including a list of tasks and a note from his daughter (Sandra).
2. The list of tasks will indicate that the host's ports are blocked, as well as something that might be the user's password. With this `sudo -l` can be run, which will allow the firewall rules to be inspected identifying that only `80` and `443` are allowed for egress.
3. The other note from Sandra will give a hint to a second note. Reading that note will provide credentials for Sandra. Moving to her account will find the **user flag** in her home directory.
4. Another note is found in her home directory though this has less useful information. Running `sudo -l` will reveal she can start and stop the tonhotel website, however as this binary is only executable and can't be modified, nor can its service file, this doesn't provide a path to privesc.
5. Her home dir also contains a folder, Pictures, and within is an image. Viewing this through the shell is not possible, so extracting it for viewing will need to be accomplished (base64 encoding for example)
6. Once opened this provides a suggestion for the final user Jojo's password.

## Final Privesc

1. In Jojo's home folder is yet another note, this one indicating that a NSF (national successionist forces) mount will be made available. This is a bit of a play on words for nfs, and a `sudo -l` will reveal JoJo can run `mount.nfs` as root.
2. Notably `mount.nfs` is not `mount`: there is no way to use the command by itself to get privilege escalation. To use it, something must be mounted that ideally has **no_root_squash** enabled (e.g. `*(rw,insecure,sync,no_subtree_check,no_root_squash)`. Exploring the machine will not find any such mounts.
3. The solution is to host a NFS mount on your attack box, and put something like a suid-set sh binary in there. Then when this is mounted by Jojo, he can run the suid binary to get root. This is complicated a little by the fact that only `80` and `443` are allowed out, not `2049`, meaning the attack box will need to host the service on one of these ports. But this is possible.

There! A room with many simple approaches complicated by conditions. If any unintended paths are discoverd, please let me know at chris@grislygrotto.nz, cheers.
