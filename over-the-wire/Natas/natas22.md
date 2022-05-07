# Natas 22

To see the site:

1. Go to [http://natas22.natas.labs.overthewire.org](http://natas22.natas.labs.overthewire.org)
2. Log in with natas22, chG9fbe1Tq2eWVMgjYYD1MsfIvN461kJ

This site returns the password if you add `revelio` to the query string. However it also includes code that will redirect the user if the user has this query string and is not admin.

To bypass and see the password, use or configure a client to not follow redirects. curl in bash will not, and a .NET `HttpWebRequest` will not either, if you set `AllowAutoRedirect` to false.

3. From bash run the following command to see the password for natas23: `curl --user natas22:chG9fbe1Tq2eWVMgjYYD1MsfIvN461kJ http://natas22.natas.labs.overthewire.org?revelio`