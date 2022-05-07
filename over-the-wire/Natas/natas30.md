# Natas 30

To see the site:

1. Go to [http://natas30.natas.labs.overthewire.org](http://natas30.natas.labs.overthewire.org)
2. Log in with natas30, wie9iexae0Daihohv8vuu3cei9wahf0e

Looking at the perl source code, its using quote(param(key)) to inject form values into a SQL script. A quick goog shows that there is a simple exploit for this: if you pass multiple form fields with the same name, the result is a list. In Perl, if you have a function that takes multiple parameters, you can instead give it a single parameter of type list that has a count equal to the parameters. And finally, quote takes two parameters, the second being the type, and if the type is said to be int (the number 4 is the constant value) then for INSANE REASONS, EVEN IF THE FIRST PARAM IS NOT AN INT, it will be returned unescaped. 

The script below passes username = `natas30`, password = `'' OR 1`, and then password again as `4`. Easy.

To get the password, run the script [natas30exploit.fsx](./natas30exploit.fsx).