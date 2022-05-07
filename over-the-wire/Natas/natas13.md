# Natas 13

1. Go to [http://natas13.natas.labs.overthewire.org](http://natas13.natas.labs.overthewire.org)
2. Log in with natas13, jmLTY0qiPZBbaKc9341cqPQZBJv7MQbY
3. Same as natas12, except server side they check if the uploaded file is an image. They still don't check the extension, so this is an easy hack.
4. Follow the same instructions as 12: change the extension in the hidden field to php, and upload the exploit file ([natas13exploit.php](./natas13exploit.php)) to get a link that will reveal the next password.

The exploit file was created by first saving a one pixel bitmap image. Then I opened the image and added the same php (with the new password path) to the end of the file. The image check finds the bitmap bytes and passes the file, and at the same time when the file is run as PHP code the bitmap bytes are treated as garbled text, before the PHP code is invoked successfully.
