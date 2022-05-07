# Bandit

[Bandit](http://overthewire.org/wargames/bandit/) is the beginner / tutorial challenge. It has, at time of writing, 32 levels (excluding 0, and with 33 being a 'Thankyou for Playing' message).

The server for bandit is at `bandit.labs.overthewire.org`, port `2220`, accessed over SSH.
To run the scripts you need to have installed **expect**, and to have SSH'd to the bandit server at least once (so you can accept the security question about the server). 

Each level requires the user with the level number, e.g. bandit0 for level 0, and the password from the previous level's result (except for level 0, which had the password bandit0)

As the bandit trials are pretty simplistic, I set myself some further restrictions:

- I am doing each challenge solely with the terminal in my Kali Linux WSL distro.
- Each level is solved in a single expect script that connects, runs the right commands and exits.
- I am creating and editing the scripts with vim.

As I am primarily a Windows user, think vim is for sociopaths and have not used the vast majority of bash tools or used expect scripts before, the constraints above have all resulted in significant learnings. Very glad I did this.
