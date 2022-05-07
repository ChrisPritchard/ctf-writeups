# Natas 17

To see the site:

1. Go to [http://natas17.natas.labs.overthewire.org](http://natas17.natas.labs.overthewire.org)
2. Log in with natas17, 8Ps3H0GWbn5rd9S7GmAdgQNdkhPkq9cw

To get the password, run the script [natas17exploit.fsx](./natas17exploit.fsx). This script logs in to the site itselfand will take a few minutes.

Explanation: This is the same challenge as natas15, except that the website no longer returns any response for success, failure or error. With no feed back, the only solution is to use a blind timing attack, which is what the script does, adding a detectable delay for success on a given query clause.