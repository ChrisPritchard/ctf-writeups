# Natas 31

To see the site:

1. Go to [http://natas31.natas.labs.overthewire.org](http://natas31.natas.labs.overthewire.org)
2. Log in with natas31, hay7aecuungiuKaezuathuk9biin0pu1

Another exploit based on idiot perl doing idiot things, in this case the fact that its `upload` CGI upload function and subsequent type assignment can be trivially bypassed (pass the param name twice, first with a string and last with an actual file, and you'll end up with the string not the file) and that the file parse syntax `<>` will, if it contains the string `ARGV`, proceed to load the query string values as if they were filenames for some fucking stupid reason.

Note: this challenge and the one previous seem to be taken directly from the black hat talks Perl Jam 2 and Perl Jam by Netanel Rubin. Fun talks. Dumb programming language.

3. To get the password, run the script [natas31exploit.fsx](./natas31exploit.fsx).

NOTE: with this one I had a bit of trouble getting the http request exactly right. In the end I used Burp Community Suite to do the exploit correctly once, then compared that against what I was sending (by using Burp as a proxy in my script). This eventually revealed to me that the boundary you set on the content type needs to be prepended by two dashes when used in the form data. Hmm.