# Knock Knock

This was a pretty trivial, guided room, but I learned a few things.

First off, this room is initially and mostly all about 'port knocking', a security technique where ports are only opened after a machine's firewall detects a certain number of syn/ack requests against a sequence of ports. To easily perform port knocking, the tool to use is called `knock`, which can be installed via the same package that also includes `knockd`, which provides the server side functionality for port knocking.

knock is used as such: `knock <ip address> <sequence of ports> -d <delay>` e.g. to knock three ports 7, 8 and 9, for ip 127.0.0.1 with an interval between knocks of 500 milliseconds, you would use `knock 127.0.0.1 7 8 9 -d 500`.

## Anyway, on to the room

The machine initially only has port 80 open. Going there allows you to download a pcap file for wireshark. In that file are three suspicious syn/ack attempts for `7000`, `8000` and `9000`, followed by a connection to `8888`. Using knock to hit the first three, I was then able to telnet to the `8888` port (I also tried nc and http, but neither worked - the hint for the question indicated the use of telnet). This just printed `/burgerworld` then exited.

Going to that directory on the main server revealed a second pcap file. Inside this one were a few port checks (21, 22, 8080) none of which did anything. The final tcp stream was a large printed portrait and a final message: eins drie drie sieben. 1337, in German.

I tried knocking on 1337, and knocking in combination with 21, 22, 8080 etc, but nothing worked. I was pretty stumped, and eventually went for some help. Ultimately the solution was to knock on ports 1, 3, 3 and 7 then connect to 1337. A bit silly.

This revealed the final sequence to unlock ssh: `8888 9999 7777 6666` and the user `butthead`. But I had no password? As silly as it was, connecting to ssh just printed the password in its greeting: `nachorules`.

The next trivial challenge was that after connecting I would get disconnected after a half second, with the message `what can you do?` or similar. Well, what I can do is give ssh a command to run: `ssh butthead@ipaddr /bin/sh`. This kept the shell open.

On the machine, poking about, I eventually found that the linux version was `3.13.0-46`. An easy overlayfs for root: `https://www.exploit-db.com/exploits/37292`. The machine had gcc installed too. Getting that c exploit script onto the machine via a webserver on kali, then compiling and running it gave me root.

Easy. I learned a bit about port knocking, which was nice :)