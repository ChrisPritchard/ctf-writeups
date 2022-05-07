# Natas 08

1. Go to [http://natas8.natas.labs.overthewire.org](http://natas8.natas.labs.overthewire.org)
2. Log in with natas8, DBfUBfqQG69KvJvJ1iAbMoIpwSNQ9bWe
3. Another form with php source; The source code compares the input secret to a constant: `3d3d516343746d4d6d6c315669563362`. The input secret is run through `bin2hex(strrev(base64_encode($secret)))`
5. Do this in reverse using `php -a` (under bash), by running: `echo base64_decode(strrev(hex2bin("3d3d516343746d4d6d6c315669563362")));`
6. Put the result into the form to get the password for natas9.
