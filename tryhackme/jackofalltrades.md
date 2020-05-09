# Jack of All Trades

Normally I don't like CTF-heavy challenges, i.e. where the box feels more like a puzzle than a real machine, but this one was kind of fun.

1. Recon revealed 22 and 80. However, I couldn't browse to 80? It said something like Format exception in firefox, and so I did a double take: the listeners were swapped! A webserver was listening on 22, while a ssh server was listening on 80 :D Firefox wouldn't let me browse to :22 for security reasons, which is fine: I proceeded with curl and wget.

2. Dirb on the webserver 22 revealed a /assets sub dir that was listable. It contained three images and a css file. I downloaded the images, then checked out the source of the root page with curl.

    > curl is fine, but when using it to navigate pages, I like to install `html2text` and pipe the html through it. Particularly for listed directories, this makes a nice readable output.

3. Given one of the images was named `stego.jpg`, I guessed this was a stegography challenge. I installed `steghide` and went looking for a passphrase. The source content of the home page revealed a couple of comments:

    ```
        <!--Note to self - If I ever get locked out I can get back in at /recovery.php! -->
        <!--  UmVtZW1iZXIgdG8gd2lzaCBKb2hueSBHcmF2ZXMgd2VsbCB3aXRoIGhpcyBjcnlwdG8gam9iaHVudGluZyEgSGlzIGVuY29kaW5nIHN5c3RlbXMgYXJlIGFtYXppbmchIEFsc28gZ290dGEgcmVtZW1iZXIgeW91ciBwYXNzd29yZDogdT9XdEtTcmFxCg== -->
    ```

4. I ran that text through `base64 -d` and got: `Remember to wish Johny Graves well with his crypto jobhunting! His encoding systems are amazing! Also gotta remember your password: u?WtKSraq`

5. I tried this password on the `stego.jpg` and got a `creds.txt` file containing: 

    ```
    Hehe. Gotcha!

    You're on the right path, but wrong image!
    ```

6. Testing the other two images, `header.jpg` contained `cms.creds` which contained:

    ```
    Here you go Jack. Good thing you thought ahead!

    Username: jackinthebox
    Password: TplFxiSHjY
    ```

7. These didn't work on ssh, but I guessed they were for the aforementioned recovery.php. I went there and found a login page. The html also contained `GQ2TOMRXME3TEN3BGZTDOMRWGUZDANRXG42TMZJWG4ZDANRXG42TOMRSGA3TANRVG4ZDOMJXGI3DCNRXG43DMZJXHE3DMMRQGY3TMMRSGA3DONZVG4ZDEMBWGU3TENZQGYZDMOJXGI3DKNTDGIYDOOJWGI3TINZWGYYTEMBWMU3DKNZSGIYDONJXGY3TCNZRG4ZDMMJSGA3DENRRGIYDMNZXGU3TEMRQG42TMMRXME3TENRTGZSTONBXGIZDCMRQGU3DEMBXHA3DCNRSGZQTEMBXGU3DENTBGIYDOMZWGI3DKNZUG4ZDMNZXGM3DQNZZGIYDMYZWGI3DQMRQGZSTMNJXGIZGGMRQGY3DMMRSGA3TKNZSGY2TOMRSG43DMMRQGZSTEMBXGU3TMNRRGY3TGYJSGA3GMNZWGY3TEZJXHE3GGMTGGMZDINZWHE2GGNBUGMZDINQ=`. Looks like base32 to me.

8. Using [cyberchef](https://gchq.github.io/CyberChef/#recipe=From_Base32('A-Z2-7%3D',true)From_Charcode('Space',16)ROT13(true,true,13)&input=R1EyVE9NUlhNRTNURU4zQkdaVERPTVJXR1VaREFOUlhHNDJUTVpKV0c0WkRBTlJYRzQyVE9NUlNHQTNUQU5SVkc0WkRPTUpYR0kzRENOUlhHNDNETVpKWEhFM0RNTVJRR1kzVE1NUlNHQTNET05aVkc0WkRFTUJXR1UzVEVOWlFHWVpETU9KWEdJM0RLTlRER0lZRE9PSldHSTNUSU5aV0dZWVRFTUJXTVUzREtOWlNHSVlET05KWEdZM1RDTlpSRzRaRE1NSlNHQTNERU5SUkdJWURNTlpYR1UzVEVNUlFHNDJUTU1SWE1FM1RFTlJUR1pTVE9OQlhHSVpEQ01SUUdVM0RFTUJYSEEzRENOUlNHWlFURU1CWEdVM0RFTlRCR0lZRE9NWldHSTNES05aVUc0WkRNTlpYR00zRFFOWlpHSVlETVlaV0dJM0RRTVJRR1pTVE1OSlhHSVpHR01SUUdZM0RNTVJTR0EzVEtOWlNHWTJUT01SU0c0M0RNTVJRR1pTVEVNQlhHVTNUTU5SUkdZM1RHWUpTR0EzR01OWldHWTNURVpKWEhFM0dHTVRHR01aRElOWldIRTJHR05CVUdNWkRJTlE9) I decoded that as base32 > from charcodes > rot13, to get the following: `Remember that the credentials to the recovery login are hidden on the homepage! I know how forgetful you are, so here's a hint: bit.ly/2TvYQ2S`. A tip to use steg hide on the images, which I had already figured out :) The link is to the wikipedia page for the stegosaurus dinosaur (which was also what the stego.jpg image was of).

9. I logged in with the recovered credentials above and got a page that said `GET me a 'cmd' and I'll run it for you Future-Jack.`

    > to log in, I decided to force firefox to let me access :22 as a webserver. The steps to do this were simple:
    > 1. go to about:config
    > 2. search for the key `network.security.ports.banned.override`
    > 3a. If it had existed, I would add `,22` on the end of its value
    > 3b. It didn't so I added it and set its value to `22`

10. Appending ?cmd=ls to the url returned ls results, so this page is basically a webshell. `whoami` returned `www-data`

11. Surprise surprise, `whereis nc` returned `nc.traditional` which meant I could use `nc -e`. With this I quickly got a reverse shell on the system.

12. In the root of `/home` there was a `/jack` folder I couldn't access, and a file called `jacks_password_list` containing the below:

    ```
    *hclqAzj+2GC+=0K
    eN<A@n^zI?FE$I5,
    X<(@zo2XrEN)#MGC
    ,,aE1K,nW3Os,afb
    ITMJpGGIqg1jn?>@
    0HguX{,fgXPE;8yF
    sjRUb4*@pz<*ZITu
    [8V7o^gl(Gjt5[WB
    yTq0jI$d}Ka<T}PD
    Sc.[[2pL<>e)vC4}
    9;}#q*,A4wd{<X.T
    M41nrFt#PcV=(3%p
    GZx.t)H$&awU;SO<
    .MVettz]a;&Z;cAC
    2fh%i9Pr5YiYIf51
    TDF@mdEd3ZQ(]hBO
    v]XBmwAk8vk5t3EF
    9iYZeZGQGG9&W4d1
    8TIFce;KjrBWTAY^
    SeUAwt7EB#fY&+yt
    n.FZvJ.x9sYe5s5d
    8lN{)g32PG,1?[pM
    z@e1PmlmQ%k5sDz@
    ow5APF>6r,y4krSo
    ```