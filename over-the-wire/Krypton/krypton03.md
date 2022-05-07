# Krypton 3

Password: `CAESARISEASY`

The readme at /krypton/krypton3/README says:

> Well done.  You've moved past an easy substitution cipher.
> 
> Hopefully you just encrypted the alphabet a plaintext
to fully expose the key in one swoop.
> 
> The main weakness of a simple substitution cipher is
repeated use of a simple key.  In the previous exercise
you were able to introduce arbitrary plaintext to expose
the key.  In this example, the cipher mechanism is not
available to you, the attacker.
> 
> However, you have been lucky.  You have intercepted more
than one message.  The password to the next level is found
in the file 'krypton4'.  You have also found 3 other files.
(found1, found2, found3)
> 
> You know the following important details:
> 
> - The message plaintexts are in English (*** very important)
> - They were produced from the same key (*** even better!)
> 
> 
> Enjoy.

The contents of `krypton3` in the same directory is: `KSVVW BGSJD SVSIS VXBMN YQUUK BNWCU ANMJS`. The other three cipher files have been copied locally for ease of analysis.

Unfortunately, I wasn't able to break this one without a hint. Frequency analysis got me to several of the characters, but I kept looking for an automated solution when I should have used those characters to guess the rest :(

Anyway, the F# script solves this using the correct key, revealing the password is `BRUTE`.