# GDB Tips and Tricks

If possible, install [GEF](https://github.com/hugsy/gef) as it makes visualising the stack and registers much easier (and has lots of other functionality as well): `bash -c "$(curl -fsSL https://gef.blah.cat/sh)"`

- `disas main` and then `b *addr` using the last ret address to break before `main` returns
- `display/i $eip` will render the contents of $eip as assembly instructions, useful for debugging shell code or nop sleds etc
- `si`: step instruction, works where `s` or `n` won't (e.g. running through an executable stack)
- `r < <(cat input.txt)` start the program with input, (not arguments, that can be done with `set args`)
- `unset env LINES` and `unset env COLUMNS` to remove gdb env vars, which can make its stack have difficult values than running outside of gdb

## Heap

- `heap chunks` to see allocated chunks (might also be in bins if freed)
- `heap bins` to see fastbins, tcache etc

## Scripting languages

Writing hex values with scripting languages is different, mainly with python3:

- plain bash `echo -e "\x41\x41\x41\x41"`
- python2: `python -c 'print "\x90" * 20 + "\x41\x41\x41\x41"'`
- perl: `perl -e 'print "\x90" x 20 . "\x41\x41\x41\x41'` note `x` instead of `*`. Also concat strings with `.` not `+`
- python3: `python3 -c 'import sys; sys.stdout.buffer.write(b"\x90" * 20 + "\x41\x41\x41\x41")'`

## Useful references

- online x86 assembler/disassembler: https://defuse.ca/online-x86-assembler.htm
- sys call table (eax with int 80): https://faculty.nps.edu/cseagle/assembly/sys_call.html
- shellcode archive: https://shell-storm.org/shellcode/index.html
- [GDB exploit guide](https://www.exploit-db.com/papers/13205)
- [pwntools cheatsheet](https://gist.github.com/ChrisPritchard/871e6aab0400e41b8158d2fcbbd38ac5)
