# Natas 05

1. Go to [http://natas5.natas.labs.overthewire.org](http://natas5.natas.labs.overthewire.org)
2. Log in with natas5, iX6IOfmpN7AYOQGPwtn3fXpbaJVJcHfq
3. The site says that you are not logged in. A quick glance at the request shows a cookie named loggedin with value 0.
4. Using Firefox or similar, find the network request for the site and edit it. Edit the cookie request header value, with the loggedin=0 changed to loggedin=1 and send.
5. Open the new request, and check the response for the password for natas6.