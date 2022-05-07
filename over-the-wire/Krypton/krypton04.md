# Krypton 4

Password: `BRUTE`

The readme at /krypton/krypton4/README says:

> Good job!
> 
> You more than likely used some form of FA and some common sense to solve that one.
> 
> So far we have worked with simple substitution ciphers. They have also been ‘monoalphabetic’, meaning using a fixed key, and giving a one to one mapping of plaintext (P) to ciphertext (C). Another type of substitution cipher is referred to as ‘polyalphabetic’, where one character of P may map to many, or all, possible ciphertext characters.
> 
> An example of a polyalphabetic cipher is called a Vigenère Cipher. It works like this:
> 
> If we use the key(K) ‘GOLD’, and P = PROCEED MEETING AS AGREED, then “add” P to K, we get C. When adding, if we exceed 25, then we roll to 0 (modulo 26).
> 
> P P R O C E E D M E E T I N G A S A G R E E D\<br />
> K G O L D G O L D G O L D G O L D G O L D G O\
> 
> becomes:
> 
> P 15 17 14 2 4 4 3 12 4 4 19 8 13 6 0 18 0 6 17 4 4 3\<br />
> K 6 14 11 3 6 14 11 3 6 14 11 3 6 14 11 3 6 14 11 3 6 14\<br />
> C 21 5 25 5 10 18 14 15 10 18 4 11 19 20 11 21 6 20 2 8 10 17\<br />
> 
> So, we get a ciphertext of:
> 
> VFZFK SOPKS ELTUL VGUCH KR
> 
> This level is a Vigenère Cipher. You have intercepted two longer, english language messages. You also have a > key piece of information. You know the key length!
> 
> For this exercise, the key length is 6. The password to level five is in the usual place, encrypted with the 6 letter key.
> 
> Have fun!

There is also a hint in /krypton/krypton4/HINT:

> Frequency analysis will still work, but you need to analyse it
by "keylength".  Analysis of cipher text at position 1, 6, 12, etc
should reveal the 1st letter of the key, in this case.  Treat this as
6 different mono-alphabetic ciphers...
> 
> Persistence and some good guesses are the key!

The content of the krypton5 file is: `HCIKV RJOX`

Additionally, two 'found' files have been copied locally for aid in analysis.

The script contains a solution for this, that produces a set of candidate clear text options. From these its clear that the password is `CLEARTEXT`. The way the solution works is derived from the instructions read [here](https://inventwithpython.com/hacking/chapter21.html), but in brief: 

1. Since we already know the keylength we split one of the large "found" strings into six strips of text - each strip or substring is made of characters entirely encoded by a single character of the key. 
2. As the character can be one of 26 characters, we try all twenty six to get different strings, then for each string we calculate how likely it is (I did this by simply checking if it contained the letter 'E' for greater than 10%.)
3. This narrows down the candidates for keys dramatically, and you can just brute force it from there to get different results.
4. I added a further check that ran through the results and filtered down to those that contained a word from a dictionary file I've included.

Complicated, but satisfying. Coding it all myself was worth it.

Update: As part of the next solution, this solution has also been modified to filter on pure plaintext, resulting in just one candidate answer.