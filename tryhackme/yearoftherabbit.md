# Year of the Rabbit

Another CTF-like room...

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