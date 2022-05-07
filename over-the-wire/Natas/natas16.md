# Natas 16

To see the site:

1. Go to [http://natas16.natas.labs.overthewire.org](http://natas16.natas.labs.overthewire.org)
2. Log in with natas16, WaIHEacj63wnNIBROHeqi3p9t0m5nhmh

To get the password: Run the script [natas16exploit.fsx](./natas16exploit.fsx) to get the password for natas17. This logs in to the site itself. Note, this will take a few minutes.

Explanation: This is a command injection attack just like natas 9 and 10. However, the grep command on the server now filters out ', " and pipe commands, and also wraps the injected value so its limited to the grep pattern - you can't escape or alter the grep invocation itself like with 9 or 10.

I had to get a hint for this, as I was not aware that in bash you can do `$(<bash code>)` in strings to run code of your own. Once I knew that, I built something that calculates, for each character index, what possible characters could be in the password - take the character from the password and find all results from the dictionary, then reduce the results to common letters only and return the final set of 'options' for that character. 

This is the 'first blind' in the script, and works well: for most characters there is only one letter candidate. There were however two problems: the dictionary didn't contain any numbers, so when there were no results the best I could determine was the char was somewhere between 0 and 9, and the outer grep command (which I cannot alter) is case insensitive - so for each char candidate, I had to consider both upper and lower case.

I got a bit stuck here, before another hint made me realised this is basically a blind injection attack, just like the previous challenge. I need to find a way to use the output of the site to get 'yes' or 'no' for some password combination. I came up with a convoluted nested grep script to do just that, but it didn't work: it used `<<< a` as the feed to an outer grep with inverse `-v`, and a regex on the start of the password for the inner grep: when a passed string matched the password, the outer grep would return 'a', which would result in data, else it would return nothing.

This didn't work for two reasons: `<<<` was being ignored for whatever reason, so I couldn't feed arbitary text to the grep (piping is disallowed by the filter), and I made the error of thinking that an empty result from a grep (no match, or match if inverse) would result in no results, just because thats what happens when you submit nothing on the website. The server in fact checks for blank input before running the grep; if the grep was run with a blank pattern, it actually returns everything. As the convoluted grep I was submitting is not blank input the grep was run everytime.

I stumbled around and found the correct solution, which is the inverse. I simplified my injected code, so that it simply matches against the password, and take advantage of the fact that a) the password isn't in the dictionary, so if my grep succeeded it would return the password which would then result in no results on the page and b) if the grep failed it would result in a blank pattern which would emit all results.

Using this inverted check, and my first blind to narrow the search data, the second blind derives the password in only a few minutes.