# Leviathan 5

Username: leviathan5
Password: Tith4cokei

The home directory contains an executable called `leviathan5`. When run it says it 'cant find /tmp/file.log'. If you create that file you will find this executable reads whatever is inside, then deletes the file (unlinks it). The executable is also a setuid for leviathan 6.

1. Easy peasy. Create a symbolic link with that file name to the leviathan 6 password, like so: `ln -s /etc/leviathan_pass/leviathan6 /tmp/file.log`
2. Run `./leviathan5` to get the password for leviathan6.