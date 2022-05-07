# Natas 09

1. Go to [http://natas9.natas.labs.overthewire.org](http://natas9.natas.labs.overthewire.org)
2. Log in with natas9, W0mMhUcRRnG8dcghE4qvk3JA9lGt8nDl
3. The php source for this site takes user input and shoves it into `passthru`, another form of php eval. The expression being evaluated is `grep -i $key dictionary.txt`
4. Entering the simple injection value `| cat /etc/natas_webpass/natas10 #` cancels the grep and dictionary filename, and prints out the password for 10.
