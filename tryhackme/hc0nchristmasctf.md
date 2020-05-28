# hc0n Christmas CTF

"hackt the planet"

Recon revealed 22, 80, and 8080. Connecting to 8080 revealed a single string:

    RwO9+7tuGJ3nc1cIhN4E31WV/qeYGLURrcS7K+Af85w=

It doesn't appear to decode from base64, 32, 62, 85 etc. Hmm.

The website at port 80 had this in its robots.txt:

    #Administrator for / is: administratorhc0nwithyhackme
    #remember, remember the famous group 3301 to solve this, the secret IV wait for you!

    User-agent: *
    Allow: iv.png 

The image iv.png appeared to be of runes, which could be nordic but to me also looked like Dwarven from Middle-Earth. I compared it against the runes for Cirth (the name of the script) used in The Hobbit via [this wikipedia page](https://en.wikipedia.org/wiki/Cirth#Runes_from_The_Hobbit) to get:

    th e i v f o r ng eo y

Incidentally, that page also revealed that the text was actually [Unicode Runic](https://en.wikipedia.org/wiki/Runic_(Unicode_block)). Translating via that page gives:

    th eh is u f o r ing yew aesc y

Not too helpful. It appears to specify the IV but its mangled. Could be a stego challenge?

Back to the website, dirb also revealed a `/admin` directory that was listable. inside was an `app-release.apk` file. Digging through that with [apktool](https://ibotpeaches.github.io/Apktool/) and grep revealed:

    .line 119
    .local v0, "decoded_data":[B
    const-string v5, "SEARCHTHESECRETKEY"

    .line 120
    .local v5, "pre_shared_key":Ljava/lang/String;
    const-string v2, "SEARCHTHESECRETIV"

    .line 121
    .local v2, "generated_iv":Ljava/lang/String;
    const-string v6, "AES/CBC/PKCS5PADDING"

This all ties back to the original string, I'm sure. So I need the IV and the secret, and no doubt if I succeed I'll get the password for the admin user.