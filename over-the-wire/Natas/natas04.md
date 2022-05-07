# Natas 04

1. Go to [http://natas4.natas.labs.overthewire.org](http://natas4.natas.labs.overthewire.org)
2. Log in with natas4, Z9tkRkWmpt9Qr7XrR5jWRkgOU901swEZ
3. The site says that the site must be accessed from http://natas5.natas.labs.overthewire.org/. This is controlled by the referer header.
4. Using Firefox or similar, find the network request for the site and edit it. Add a 'Referer' header with the required origin and send.

    > Referer: http://natas5.natas.labs.overthewire.org/

5. Open the new request, and check the response for the password for natas5.