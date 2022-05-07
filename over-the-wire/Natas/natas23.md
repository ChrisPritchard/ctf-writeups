# Natas 23

To see the site:

1. Go to [http://natas23.natas.labs.overthewire.org](http://natas23.natas.labs.overthewire.org)
2. Log in with natas23, D0vlad33nQF0Hz2EP255TP5wSW9ZsRSE

This page will return the password if the passwd contains the text "iloveyou" and if the text is greater than 10. The ability for these both to be true is due to PHP type juggling / eager casting: if a string starts with a number, and is compared with a number, then the starting number is parsed to a number for the comparison - the rest of the string is ignored.

3. Submit `11iloveyou` as the password to get the password for natas24.