# Natas 19

To see the site:

1. Go to [http://natas19.natas.labs.overthewire.org](http://natas19.natas.labs.overthewire.org)
2. Log in with natas19, 4IwIrekcuZlA9OsjOkoUtwU6lhokCPYs

To get the password: Run the script [natas19exploit.fsx](./natas19exploit.fsx) to get the password for natas20. This logs in to the site itself. Note, this will take a few minutes.

Explanation:

Cookies set by the site for usernames (found by going through the normal form): 

- helloworld    37302d68656c6c6f776f726c64
- natas17       3132302d6e617461733137
- natas17 (2)   3431302d6e617461733137
- natas17 (3)   3336332d6e617461733137
- natas18       3134342d6e617461733138

Looks like hex data. By using PHP from PHP interactive:

    `echo pack("H*", "3132302d6e617461733137");` results in `120-natas17`

So its same as the previous challenge, except the username (admin) is appended after a dash to the session key, then hex encoded.