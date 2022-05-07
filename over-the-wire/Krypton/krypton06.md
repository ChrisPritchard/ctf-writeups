# Krypton 6

Password: `RANDOM`

> The readme at /krypton/krypton6 says:
> 
> Hopefully by now its obvious that encryption using repeating keys is a bad idea.  Frequency analysis can destroy repeating/fixed key substitution crypto.
> 
> A feature of good crypto is random ciphertext.  A good cipher must not reveal any clues about the plaintext.  Since natural language plaintext (in this case, English) contains patterns, it is left up to the encryption key or the encryption algorithm to add the 'randomness'.
> 
> Modern ciphers are similar to older plain substitution ciphers, but improve the 'random' nature of the key.
> 
> An example of an older cipher using a complex, random, large key is a vigniere using a key of the same size of the plaintext. For example, imagine you and your confident have agreed on a key using the book 'A Tale of Two Cities' as your key, in 256 byte blocks.
> 
> The cipher works as such:
> 
> Each plaintext message is broken into 256 byte blocks.  For each block of plaintext, a corresponding 256 byte block from the book is used as the key, starting from the first chapter, and progressing. No part of the book is ever re-used as key.  The use of a key of the same length as the plaintext, and only using it once is called a "One Time Pad".
> 
> Look in the krypton6/onetime  directory.  You will find a file called 'plain1', a 256 byte block.  You will also see a file 'key1', the first 256 bytes of 'A Tale of Two Cities'.  The file 'cipher1' is the cipher text of plain1.  As you can see (and try) it is very difficult to break the cipher without the key knowledge.
> 
> (NOTE - it is possible though.  Using plain language as a one time pad key has a weakness.  As a secondary challenge, open README in that directory)
> 
> If the encryption is truly random letters, and only used once, then it is impossible to break.  A truly random "One Time Pad" key cannot be broken.  Consider intercepting a ciphertext message of 1000 bytes.  One could brute force for the key, but due to the random key nature, you would produce every single valid 1000 letter plaintext as well.  Who is to know which is the real plaintext?!?
> 
> Choosing keys that are the same size as the plaintext is impractical. Therefore, other methods must be used to obscure ciphertext against frequency analysis in a simple substitution cipher.  The impracticality of an 'infinite' key means that the randomness, or entropy, of the encryption is introduced via the method.
> 
> We have seen the method of 'substitution'.  Even in modern crypto, substitution is a valid technique.  Another technique is 'transposition', or swapping of bytes.
> 
> Modern ciphers break into two types; symmetric and asymmetric.
> 
> Symmetric ciphers come in two flavours: block and stream.
> 
> Until now, we have been playing with classical ciphers, approximating 'block' ciphers.  A block cipher is done in fixed size blocks (suprise!). For example, in the previous paragraphs we discussed breaking text and keys into 256 byte blocks, and working on those blocks.  Block ciphers use a fixed key to perform substituion and transposition ciphers on each block discretely.
> 
> Its time to employ a stream cipher.  A stream cipher attempts to create an on-the-fly 'random' keystream to encrypt the incoming plaintext one byte at a time. Typically, the 'random' key byte is xor'd with the plaintext to produce the ciphertext.  If the random keystream can be replicated at the recieving end, then a further xor will produce the plaintext once again.
> 
> From this example forward, we will be working with bytes, not ASCII text, so a hex editor/dumper like hexdump is a necessity.  Now is the right time to start to learn to use tools like cryptool.
> 
> In this example, the keyfile is in your directory, however it is not readable by you.  The binary 'encrypt6' is also available. It will read the keyfile and encrypt any message you desire, using the key AND a 'random' number.  You get to perform a 'known ciphertext' attack by introducing plaintext of your choice. The challenge here is not simple, but the 'random' number generator is weak.
> 
> As stated, it is now that we suggest you begin to use public tools, like cryptool, to help in your analysis.  You will most likely need a hint to get going. See 'HINT1' if you need a kicktstart.
> 
> If you have further difficulty, there is a hint in 'HINT2'.
> 
> The password for level 7 (krypton7) is encrypted with 'encrypt6'.
> 
> Good Luck!

The contents of krypton7 is `PNUKLYLWRQKGKBE`

Based on the hints and the readme above, I figured I needed to get the random sequence out. If I had a list of the random numbers used, I could reverse them on the cipher text and derive the key, given I control the plaintext. First step is to create a long file containing the results of encrypting just one character - I used 'x'.

To set this up, I had a bit of trouble. I tried using `mktemp -d` to create a working dir, but running `encrypt6` with plaintext in that folder kept complaining that it couldn't open the plaintext. A reverse technique where you operate from the random folder, and use symlinks to ensure a local copy of the keyfile is present (its owned by krypton7, so can't just be copied) didn't work either. Ultimately it looks like it was a bug of some sort: mktemp creates folders like this: `tmp.M8SztyfWDr`. If I created a folder in tmp called `chrisp` instead, it worked fine. Some parsing issue in the executable maybe?

I created the file in bash using this command: `{ for i in {1..1000}; do echo -n x; done } > plaintext`

This resulted in the following ciphertext: `BFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVWHQEKPFOCUVZMCRBLZHOKBFZQADVFVW`

Which exposes the repeated, 30-character token: `BFZQADVFVWHQEKPFOCUVZMCRBLZHOK`

If do the same for 'y' the token is: `CGARBEWGWXIRFLQGPDVWANDSCMAIPL` and for 'z' it is: `DHBSCFXHXYJSGMRHQEWXBOETDNBJQM`

The next test is to determine if a given character's cipher is based on the previous cipher, so I encrypted a 30 character text made up of 15 of 'x' followed by 15 of 'y' to get `BFZQADVFVWHQEKPGPDVWANDSCMAIPL`. As this matches the first and second half of the tokens above, there is no dependency on previous char, making the rest of this problem easy.

1. Assuming that the plaintext for krypton7 will be the same as all the other passwords, I need to only derive the 30 character 'index keys' (the tokens above) for the characters 'A' to 'Z'.
2. Once done, I can load the results into a script and pivot them into 30 strips of alphabets-by-index.
3. To derive the plaintext, each character of the cipher is looked up by its index in the string mod 30 (though its less than 30 characters so mod won't be necessary), then its index in the 'alphabet' is found to derive the plaintext char: e.g. index 4 corresponds to B, and 3 to C.

I encrypted the alphabet on the remote server, copying the result of `grep "" *` into the file krypton6chosenCiphertext so it could be read via the F# script. The password for Krypton7 is `LFSRISNOTRANDOM`.

There is no Krypton 7 (though the password above works), so this is the end of Krypton!