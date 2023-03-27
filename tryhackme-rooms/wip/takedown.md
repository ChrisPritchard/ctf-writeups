# Takedown

https://tryhackme.com/room/takedown

Rated "INSANE"

- the server exposes port 80 (TODO CHECK)
- on the site, the favicon.ico is a windows binary. Additionally, under /images is shuttlebug.jpg.bak (an IoC according to the rooms intro) which is also a binary. These are the same program, for windows and linux.

Which binary you reverse doesn't matter so much, as much as what it does. Opening them with Ghidra shows they are nim binaries, which is a bit tricky to reverse but still possible.

- the entry point is the function `NimMainModule`
- it checks two flags, -v and -h. -h prints a short help message, while -v is presumably 'verbose', as it prints status messages
- first thing it does is run whoami, checking the response against a hardcoded username 'c.oberst', as the 'keyed username'.
- after that, in initial_check_in__main, it makes an api request with the hostname given. this is to `http://takedown.thm.local/api/agents/register`, with the user-agent `Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0 z.5.x.2.l.8.y.5` and content type `application/json`. the content sent is `{"uid":"","hostname":""}` with the uid and hostname from the app
