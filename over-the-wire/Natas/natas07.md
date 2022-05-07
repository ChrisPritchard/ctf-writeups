# Natas 07

1. Go to [http://natas7.natas.labs.overthewire.org](http://natas7.natas.labs.overthewire.org)
2. Log in with natas7, 7z3hEENjQtflzgnT29q7wAvMNfZdh0i9
3. The links to 'home' and 'about' pass the path of the file to open in the query string. The source of the page says the password for 8 is at `/etc/natas_webpass/natas8`
4. Navigate to home or about, and change the path in the query string to `/etc/natas_webpass/natas8` to get the password for nata8 rendered on screen.
