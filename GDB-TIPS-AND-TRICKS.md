# GDB Tips and Tricks

- `disas main` and then `b *addr` using the last ret address to break before `main` returns
- `display/i $eip` will render the contents of $eip as assembly instructions, useful for debugging shell code or nop sleds etc
- `si`: step instruction, works where `s` or `n` won't (e.g. running through an executable stack)
- `r < <(cat input.txt)` start the program with input, (not arguments, that can be done with `set args`)
- `unset env LINES` and `unset env COLUMNS` to remove gdb env vars, which can make its stack have difficult values than running outside of gdb

## Useful references

- online x86 assembler/disassembler: https://defuse.ca/online-x86-assembler.htm
- sys call table (eax with int 80): https://faculty.nps.edu/cseagle/assembly/sys_call.html
- shellcode archive: https://shell-storm.org/shellcode/index.html
- [GDB exploit guide](https://www.exploit-db.com/papers/13205)
