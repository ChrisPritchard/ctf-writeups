# Leviathan 6

Username: leviathan6
Password: UgaoFee4li

The home directory contains an executable called `leviathan6` which when run says it needs to be run with a 4 digit code. Disassembling the binary shows that it moves the number 7123 (hex `1BD3`) into `$ebp-0xC`, which is then compared against the user parameter when specified (the user parameter is converted to an integer via `atoi()`).

1. Run the executable with the number argument like so: `./leviathan6 7123`. It should show a shell prompt.
2. Run `cat /etc/leviathan_pass/leviathan7` from the prompt to get the password for leviathan7.