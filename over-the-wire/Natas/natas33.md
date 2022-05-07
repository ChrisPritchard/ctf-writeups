# Natas 33

To see the site:

1. Go to [http://natas33.natas.labs.overthewire.org](http://natas33.natas.labs.overthewire.org)
2. Log in with natas33, shoogeiGa2yee3de6Aex8uaXeech5eey

For this challenge, the page allows you to upload a file and then checks that file against a md5 hash. If it matches, the file is run as PHP. The code for this challenge uses a class with a constructor/destructor to perform its logic.

Initially I missed the hint to the earlier challenge involving unserialization of a destructor class - its less obvious here because there is no call to unserialize anywhere. I had a go at trying to generate a collision on the md5, but that failed (I know md5 is weak, but its still enough to fool my efforts). After that I did a bit of research around the common commands being used, like md5_file, since that wrapped my controlled input, and I discovered the exploit summarised here: [What is Phar Deserialization](https://blog.ripstech.com/2018/new-php-exploitation-technique/).

I built almost all of this solution myself, based on the above, but required a hint for the final step below. Note, I also couldn't get this to work until I used Burps suite for it. Firefox edit-and-resend is just not as effective.

3. Using the site, upload the payload file [natas33payload.php](./natas33payload.php), but change the filename form parameter to `payload.php`. You can change this using Firefox or Burps (burps was easier - intersept and send to repeater a request then modify at will).
4. Create the phar file; A phar file has already been added to this repo, but the script [natas33create-exploit.php](./natas33create-exploit.php) will recreate it when run `php natas33create-exploit.php`
5. Upload the phar file, changing its filename to `exploit.php`
6. Finally, upload the phar file again (or any file), but this time set the filename to `phar://exploit.php/trigger.txt`

The password will be presented at the base of the page/source.