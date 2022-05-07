# Natas 28

To see the site:

1. Go to [http://natas28.natas.labs.overthewire.org](http://natas28.natas.labs.overthewire.org)
2. Log in with natas28, JWwR438wkgTsNKBbcJoowyysdM82YjeF

Initial observations from submitting something to the form is that the query parameter on the redirected-to form needs to be altered. Its our entry point - our source. There doesn't seem to be any other ways in.
The string looks base64, but when decoding I get nothing. Tried several different encodings to no luck. Then I submitted just some random text, and got the error 'Incorrect amount of PKCS#7 padding for blocksize' displayed.

Cool, so its an encrypted string. Er...

Thats about the extent of my knowledge, so I looked for a tip and found out that the vuln to exploit is an 'ECB attack'. ECB stands for 'Electronic Code Book' and is a block cypher mode where each block of the plaintext is encrypted independently: meaning two blocks of the same plaintext evaluate to the same ciphertext. This has a number of serious problems, which is why alternatives like CBC are used.

## ECB attack stage

EBC is vulnerable because if can control some of the plaintext (as we can here), you can derive the rest of the plain text by exploiting the block cypher: expand your text with the same characters until two blocks are identical, at which point you know both blocks contain just your characters. Then reduce your characters by one and note the resulting value (which is generated from your characters plus one character of the text you are recovering). Then submit your characters plus all 256 byte combinations until you find the one that matches the hash you got before: boom, you have derived one character of the encrypted text. Repeat to get the rest.

The script [natas28ecb-attack.fsx](./natas28ecb-attack.fsx) does the above, also handling the query and response encoding/decoding. However, if you run it, you will see only a single character is derived: `%`. The rest is not parsed, which is likely due to `%` being the end of a `LIKE '%string%'` expression - the `'` the follows is encoded away sometime between submitting and it being encrypted. Without being able to submit the raw `'` through the query and have it end up in the script, our ECB attack comes to an end.

## Exploit stage

Assuming the script is something like `SELECT * FROM Jokes WHERE text LIKE '%string%'` we need to inject something like `' UNION ALL SELECT password FROM Users #`. However, as mentioned, we cannot submit a `'` to break out of the `LIKE` through the query - it would get escaped with `\'`. However HOWEVER, if we can stick the injected plaintext in such a way that the `\'` overlap a block boundary, we can copy the block with just the `'` (!), then inject this block into a simpler query to get the ' we want!!!

This is what [natas28exploit.fsx](./natas28exploit.fsx) does. Note, it takes as constants the blocksize and offsets calculated by the ECB attacks, so these steps don't need to be repeated. Run the script to get the password for natas29.

## Summary

This one was very hard, and I had to get a full tutorial to figure it out. But I learnt a lot, and all the code used is my own so I am happy.