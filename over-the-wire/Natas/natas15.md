# Natas 15

To see the site:

1. Go to [http://natas15.natas.labs.overthewire.org](http://natas15.natas.labs.overthewire.org)
2. Log in with natas15, AwWj0w5cvxrZiONgZ9J5stNVkmxdk39J

To get the password: Run the script [natas15exploit.fsx](./natas15exploit.fsx) to get the password for natas16. This logs in to the site itself. Note, this will take a few minutes.

Explanation: Another SQL injection attack, but one which doesn't return any data or error messages. After checking the PHP functions for bugs, then playing around with extracting the password using 'select into' and trying to save it into an accessible location, I ended up looking for help. Turns out the key is a 'blind sql attack'.

The sql injection allows you to extend the select clause with more where clauses, and using that and LIKE, you can build a series of queries (it helps that the PHP accepts either a get as well as the standard post) that will return yes or no on the website when submitted, allowing you to slowly extract the password. Impossibly complicated by hand, but easy (if a little time consuming) by script.