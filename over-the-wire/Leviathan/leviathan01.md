# Leviathan 1

Username: leviathan1
Password: rioGegei8m

1. Access with SSH using the given credentials.
2. There is a setuid binary in the home directory that demands a password. Run it with ltrace to see what its checking: `ltrace ./check`
3. After getting the password, run the binary again to get shell access as leviathan2.
4. Run `cat /etc/leviathan_pass/leviathan2` to get the password for the next level.