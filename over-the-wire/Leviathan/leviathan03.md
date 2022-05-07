# Leviathan 3

Username: leviathan3
Password: Ahdiemoo1j

There is a binary in home folder called level3, that prompts the user for a password. If the correct one is given, the user is place in a shell where you can read the password for level4.

I made a massive error with this one. While I quickly found the password via `ltrace`, the shell was always still using leviathan3, rather than leviathan4. Bearing in mind my failure from the previous level, I spent a lot of time with the disassembly. Learnt a lot, did a lot of work changing bits and memory. There seemed to be two strings compared first, before the password check: `h0no33` and `kakaka`. If that checked passed (which it wouldn't) some bit was being set. I figured that if I could hack it to pass then the bit would control whether setuid is run properly. But after learning how to change the bits, the problem I always ran into was a `gdb`-ed binary, or one altered with `xxd` etc, would change ownership to the current user! Even if setuid was written correctly, I wouldn't get elevated priviledges.

I was stumped, and looked for a hint. To my surpise, the solution was just to submit the password I initially found and use the shell. But that didn't work for me! Then, massive /facepalm: of course it didn't work for me, because when I did it, I did so as part of the ltrace. ltrace prevents setuid from working. Not sure what the h0n033 and kakaka (along with two others in the file, bombad and s3cr3t) - possibly all just misdirection to throw off the use of `strings` or something.

1. Run ./level3
2. Enter the password when prompted `snlprintf`
3. Once in the shell, run the command `cat /etc/leviathan_pass/leviathan4` to get the password.