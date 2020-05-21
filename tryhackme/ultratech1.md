# UltraTech

"The basics of Penetration Testing, Enumeration, Privilege Escalation and WebApp testing"

A fun room. Had some difficulty enumerating, but ultimately solved it without any help. Took longer than I would have liked though - but it was a fairly clever room.

1. Recon revealed 21, 22, 8081 and 31331. The last two were two websites: 8081 was a node.js 'rest' api, and 31331 a static html website running on apache.

2. `robots.txt` for the website revealed a `utech_sitemap.txt` file, which contained a path I didn't find through dirb: `partners.html`. This was a login page that, through javascript, invoked two urls on the api:

    ```javascript
        (function() {
        console.warn('Debugging ::');

        function getAPIURL() {
        return `${window.location.hostname}:8081`
        }
        
        function checkAPIStatus() {
        const req = new XMLHttpRequest();
        try {
            const url = `http://${getAPIURL()}/ping?ip=${window.location.hostname}`
            req.open('GET', url, true);
            req.onload = function (e) {
            if (req.readyState === 4) {
                if (req.status === 200) {
                console.log('The api seems to be running')
                } else {
                console.error(req.statusText);
                }
            }
            };
            req.onerror = function (e) {
            console.error(xhr.statusText);
            };
            req.send(null);
        }
        catch (e) {
            console.error(e)
            console.log('API Error');
        }
        }
        checkAPIStatus()
        const interval = setInterval(checkAPIStatus, 10000);
        const form = document.querySelector('form')
        form.action = `http://${getAPIURL()}/auth`;
        
    })();
    ```

3. Going to that `/ping?ip=` on the api revealed output that looked like the output of a native bash ping command. So...command injection.

4. I could confirm it partially worked via ```/ping?ip=`ls` ``` which gave a single file: `utech.db.sqlite`. But how to get that out?

5. I tried numerous things. Common injection like `&` or `|` did nothing - in fact, I suspect they were bing trimmed since `120.0.0.1|test` was printed as an error like `no domain named 127.0.0.1test`. `nc` was on the machine, but not the mc that uses `-e`. However, using nc, I was able to tickle my kali reverse proxy, so I guessed a proper reverse shell might be possible.

6. Ultimately I used three steps: first I encoded a reverse shell script using base64, then I used the injection to emit it: `echo encoded > shell.t`. Next I used `base64 -d shell.t > shell.o`, and finally I invoked the reverse shell via `bash shell.o`. No pipes required.

7. Once on the box I was able to inspect the `utech.db.sqlite` file from before (a simple `cat` worked, given its tiny) revealed two users with password hashes in md5. `r00t` had a home folder, so I took his/her hash and cracked it with hashcat, then dropped my reverse shell and ssh'd in normally.

8. Enumeration revealed nothing obvious. However docker was installed. Given the page had said (and the auth / login page had said the same when I logged in with one of the cracked hashes) that `the intern had misconfigured something`, I guessed that something was probably running as root when it shouldn't have been. `id -Gn` revealed `r00t` was part of the docker group.

9. I scp'd an alpine docker image onto the machine, then ran it with `docker run -v /:/mnt --rm -it alpine chroot /mnt sh` and BOOM! root shell :)

The final question in the room was the first nine characters of the root user's ssh private key, which was found in `/root/.ssh/id_rsa`. Easy (took me hours, one of which was spent looking everywhere BUT docker)!