# Krypton 5

Password: `CLEARTEXT`

The readme at /krypton/krypton5 says:

> Frequency analysis can break a known key length as well.  Lets try one
> last polyalphabetic cipher, but this time the key length is unknown.
> 
> Enjoy.

The contents of the cipher text is `BELOS Z`

This task is the same as the previous, except the keylength is not known. Using [the same link](https://inventwithpython.com/hacking/chapter21.html) from the previous task, there is a description on deriving key lengths using repeated sequences. The F# script implements this, finds the keylength, then passes it to the same function used in Krypton 4. 

The solution derived was `RANDOM`. As part of this, I've modified the viginere cracker to narrow down to pure english plaintext, which results in one correct answer for both this and the previous solution.