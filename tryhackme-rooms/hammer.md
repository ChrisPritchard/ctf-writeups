# Hammer

https://tryhackme.com/r/room/hammer
A medium rated room, that involves an auth bypass and JWT forging.

1. A scan will reveal 22 and 1337, with a website on the latter
2. Accessing the site presents a login page and a forget_password page. Additionally, in the source for the login page there is a note saying sub folders will have the prefix `hmr_`
3. A fuzz with this sub folder name will a logging folder; within is an error log file that can be read. This contains a few things, but most importantly a valid email address
4. Using this on forget_password will redirect to a screen where, thanks to some javascript, three minutes are allowed to submit the valid 4-digit code. Trying to simply brute force this (180 seconds is more than enough to submit 10000 codes via a tool) will fail, due to rate-limiting
5. The rate-limiting is presented in a header, and allows 10 attempts. A little experimentation will reveal it is tied to source IP, and can be bypassed with the header `x-forwarded-for`
6. By running an intruder or fuzz attack within the 180 seconds allowed, over all possible codes (its also possible to submit the code for the aforementioned header) the forgot_password page will on refresh become a reset_password page
7. Resetting the password and then logging in will reveal a dashboard where the user can submit commands (first **flag** will be here). Looking at the javascript, this makes an API call passing a JWT bearer token for auth
8. The only command that will work is `ls`, with no arguments (also after compromise you can see that `cat composer.json` is also permitted). This will reveal a key file in the local web dir, which can be browsed to to extract its value.
9. The JWT, when submitted into JWT.io, reveals in its payload the role of the user, which is unprivileged. Using JWT.io or other tools, this can be changed to 'admin'.
10. To make the JWT valid and accepted for the site, use the retrieved key value as its signing key. The JWT also contains in its header the path to the key used: this needs to be updated to the path of the xposed key. The web directory is in the log file from earlier, and the key name is already known so the correct path can be constructed.
11. Once the JWT is being accepted, the command runner no longer has any restrictions. The path to the final **flag** is part of the question, `/home/ubuntu/flag.txt` - this can be retrieved via the API, or a shell can be obtained and it can be retrieved directly.

A fairly straightforward room, but a few people were tripped up by the JWT composition it seemed. Either because they were using more complicated tools for composing the JWT (so selecting ciphers and the like might have caused trouble) or because they did not update the key path directly. For the latter issue, the main problems seemed to be not correlating the key value they used for signing with the idea that they needed to specify that key in the header, or using the wrong web directory path. 
