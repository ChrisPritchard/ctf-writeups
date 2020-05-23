# Lord of the Root

"A box to demonstrate typical CTF strategies."

This one was easy right up to getting root on the box, which was beyond me. However, I'll document it all up plus the three strategies for root which I learned about and tested, as they represent some good learnings.

1. Scanning revealed just two ports, 22 and 1337. The latter hosted a simple static website that was lord of the rings themed.

2. Browsing to robots.txt surprisingly revealed another static page, with another image. In the source was a base64 encoded string, which when decoded gave `/978345210/profile.php`

3. On that page was a simple login form. I promptly ran `sqlmap` against it, and found the password field was injectable. Via that I ran a `--dump` and got a single table of username/passwords:

    ```
    +----+------------------+----------+
    | id | password         | username |
    +----+------------------+----------+
    | 1  | iwilltakethering | frodo    |
    | 2  | MyPreciousR00t   | smeagol  |
    | 3  | AndMySword       | aragorn  |
    | 4  | AndMyBow         | legolas  |
    | 5  | AndMyAxe         | gimli    |
    +----+------------------+----------+
    ```

4. Any of them worked on the login form, but the resulting page had nothing on it. Next step was to test it against the ssh endpoint.

5. I popped those usernames and passwords into two separate files and ran them with hydra against ssh. It popped with `smeagol:MyPreciousR00t` in a moment. I logged on and started internal enumeration.

