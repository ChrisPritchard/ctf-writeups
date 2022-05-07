# Leviathan 2

Username: leviathan2
Password: ougahZi8Ta

1. Access with SSH using the given credentials.
2. The local printfile setuid executable will emit the contents of any file specified, however it doesnt work for the password file. Dissasemble its main function to see what it does.

Redare2 is a nice tool for this. Use r2 on the vm, or install it locally, the run it against the executable. `aaa` followed by `afl` followed by `s sym.main` followed by `pdf` reveals the program flow.

3. First it calls `access()` (a system function, which I didn't realise initially) to check if the user has rights for the file, then it passes the filename to a cat command.

I got a hint for this one, mainly because I found access() confusing. If I had spent more time thinking about it, I would have seen that its not part of the main source and instead an external function. Assembly is still a bit imtimidating to me, and this challenge taught me that I need to take some time to study it properly.

Anyway...the key to this solution is symbolic links, which I also didn't know much about and have spent time to learn for this challenge.

4. Create a symbolic link in the tmp directory that points to the password file. E.g. `ln -s /etc/leviathan_pass/leviathan3 /tmp/link`
5. Create a file in the tmp directory with a space in its name, and with its second part being the name of your link, e.g. `touch "/tmp/trick link"`
6. Use printfile on the symbolic link - you will have to do this from the tmp directory mostlike.

The password will be printed after an error about not finding 'trick' anywhere. Why does this work? `access` is passed the filepath properly, and tests if you own "trick link" (which you do). But the call to cat is by string interpolation, so cat is run like `/bin/cat trick link`. This is a valid cat command to read both files.

