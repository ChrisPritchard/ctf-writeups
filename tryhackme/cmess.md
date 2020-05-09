# CMesS

"Can you root this Gila CMS box?"

An important instruction was to specify `cmess.thm` as a host entry for the machine IP. This perhaps was a hint to the first way in.

1. Recon showed just 22 and 80. I ran dirb, nikto and got a huge number of false positives, but no way in. The CMS, gila, had a couple of vulns but they all required access.

2. On the TryHackMe page the 'user flag' question has a hint, "Have you tried fuzzing subdomains?". I hadn't, and indeed haven't before. I figured I would try with wfuzz.

    The problem with subdomains is that in order to use them, I need to specify the host entry for them. With all but a very minimal set, that would be hundreds of entries: I can't just `wfuzz http://FUZZ.cmess.thm` for example. However, a host entry is equivalent to going to an IP and specifying a Host header, so this works:

    `wfuzz -w /usr/share/wordlists/wfuzz/general/common.txt -H "Host: FUZZ.cmess.thm" 10.10.25.158`

    Running this, I got 200 ok codes for almost every entry. However, I was able to tell a difference via size:

    ```
    ...
    000000058:   200        107 L    290 W    3907 Ch     "announcements"
    000000178:   200        107 L    290 W    3874 Ch     "cm"
    000000190:   200        107 L    290 W    3898 Ch     "compressed"
    000000256:   200        30 L     104 W    934 Ch      "dev"
    000000196:   200        107 L    290 W    3895 Ch     "configure"
    000000204:   200        107 L    290 W    3889 Ch     "content"
    000000215:   200        107 L    290 W    3886 Ch     "cpanel"
    000000228:   200        107 L    290 W    3877 Ch     "cvs"
    ...
    ```

3. Setting up an entry (could have also used curl with an explicit header) for `dev.cmess.thm`, going there returned a chat log:

    ```
    Development Log
    andre@cmess.thm

    Have you guys fixed the bug that was found on live?
    support@cmess.thm

    Hey Andre, We have managed to fix the misconfigured .htaccess file, we're hoping to patch it in the upcoming patch!
    support@cmess.thm

    Update! We have had to delay the patch due to unforeseen circumstances
    andre@cmess.thm

    That's ok, can you guys reset my password if you get a moment, I seem to be unable to get onto the admin panel.
    support@cmess.thm

    Your password has been reset. Here: KPFTN_f2yxe%
    ```

4. I was able to log in with `andre@cmess.thm` and `KPFTN_f2yxe%` via `/login` and got access to the admin panel.