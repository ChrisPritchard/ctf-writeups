# OSCP Guide

Tips, Tricks and Advice for obtaining the OSCP certification

> Note: I took the exam in 2021, and this writeup was initially made for my work colleagues. The OSCP *you* take may not match this format - some notes about how they have added Active Directory work since. So don't treat this as a hundred percent accurate guide, though many parts (I hope) will still be useful.

## Introduction

Overall note: the OSCP exam is basically a CTF challenge in a limited time period, so the training material and even the labs in the PEN-200 course might not necessarily prepare you for it. Below are tips, resources and notes that are more exclusively about exam passing.

## Exam Format

Basically, you will provided with six machines: four boot2roots, at 10, 20, 20 and 25 points, and a pair of machines one with a service listening that you need to perform a buffer overflow on, and another machine which you can remote desktop to and which contains both the service binary and immunity debugger with mona installed. The buffer overflow is worth 25pts.

To pass you need to obtain at least 70 points. E.g. if you get a 20 and 25 boot2root, and then the buffer overflow, that is a pass.

### Tool restrictions

You can't use any 'auto-exploitation' tools. In practice, this means you should avoid metasploit (msfvenom is fine however), sqlmap, and any other tool where it will both discover AND auto-exploit vulnerabilities. With metasploit you may use it just once - the 10pt machine seems to be designed for this purpose, but as a suggestion I (Chris P) would attempt to do even that just with a public exploit from exploit-db rather than using metasploit (unless you are strapped for time or something).

### Intro text

The introduction provided by OFFSEC on the control panel lists the five machines with their IP addresses, what point value they have, and whether there is both a local and proof file you need or just a proof file (e.g. for the 10pt and buffer overflow machines). Additionally it provides the credentials and login commands for the buffer overflow mirror machine.

## Approach

How you approach the exam is personal, but there is some general guidance and suggestions here.

- Some suggest the following: using a tool like auto recon to scan all machines while you focus on the buffer overflow, then once thats done, using the autorecon results to work on one machine at a time, with fixed limits (e.g. two hours a machine so you don't get stuck)
- My approach was very different: I ran a quick nmap scan on each machine in five terminal windows (only needed four, but I didn't read the instructions lol), which gave me immediate things to poke at like port 80 etc. I then flitted between the machines whenever anything took a while (e.g. gobusting) or I didn't immediately find a path forward. I also ran long, slow but full port scans on boxes when I was working on a particular exploit for a different machine - catching sneaky high ports can be very important.
- Take lots of screenshots and notes as you go - if you can, assuming you get the requisite points - start writing the report during the exam time so you can take more screenshots as needed. For me, I took a bunch of screenshots and notes in the first seven hours (which, TW: bragging, was how long it took me to compromise all five machines) then slept without ending the exam, so the following morning I could finish my report while I still had access. And I needed that, as there were a lot more or better screenshots I felt I needed to take.
- If possible, I'd suggest not doing the buffer overflow first. If you have studied for it properly (see the section), it should be an easy 25 pts. If you get a 20 and a 25 first, or maybe the 10 and two 20s, then the buffer overflow marks a guarenteed pass. This was my experience (largely by accident - I didn't know which was the buffer overflow because I didn't read the instructions, and compromised the 20 and 25 first) and is a great feeling that drops all pressure off you.

## Generic Exam Tips

- The servers are in the US or the UK or somewhere. I.e. rustscan is going to be too slow to work, and even autorecon might fail. Nmap and time management might be better from NZ/AU
- You can use [Linpeas](https://github.com/carlospolop/PEASS-ng/tree/master/linPEAS) and [Winpeas](https://github.com/carlospolop/PEASS-ng/tree/master/winPEAS) for machine enumeration once you have obtained local access. Linpeas will partially work on linux-like operating systems like freebsd as well, if you encounter it. For these tools, note you can't use any auto-exploitation options these might support (though given how often they're used in OSCP the creator tries to avoid this functionality, at least by default)
- You can also use linux exploit suggester or other tools that attempt to discover kernel exploits
- You can have the course material and excellent resources like [hacktricks](https://book.hacktricks.xyz/) open - there seems to be no restriction on what you can reference short of actual writeups.
- The debugging machine for the buffer overflow was a struggle to connect to - it didn't work with remmina or even raw Windows remote desktop (if you have a Windows machine handy as I (Chris P) did). However, if you eventually RTFM you will note in the instructions that redesktop is recommended, and works great.
- The proctor does not record audio. Crank those tunes! They're also generous with breaks - I took a 5-15 min break every hour for food and coffee and er... ablutions breaks... and there was no drama. You just have to tell them when you leave and tell them when you return.
- As a follow up, take breaks! Often if you can. And relax! Stay calm! Get a good sleep! Beating your head against a machine for five hours isn't going to help you solve it, and may stop you solving anything else. If whatever you are doing is too hard, you are either working on a rabbit hole or need a different perspective; get stuck? Take a walk.

## Buffer Overflow Prep

The buffer overflow in the exam is worth 25 pts, and is a very basic ret2esp overflow that you might be able to knock out in half an hour with a bit of prep. So how do you prep?

The best resource in my experience is a room on TryHackMe: https://tryhackme.com/room/bufferoverflowprep

This room is free for anyone (you don't need a TryHackMe subscription, though I recommend one because its an awesome infosec training resource), It contains 10 challenges, all of which are basically the same with different offsets; the idea is to practice over and over until you are super comfortable. The first challenge includes all the steps you need, and is a really effective tutorial for the process.

Additionally, I have condensed the steps [here on my github](https://github.com/ChrisPritchard/ctf-writeups/blob/master/BUFFER-OVERFLOW-2.md).

Finally, there is [this awesome site](https://ir0nstone.gitbook.io/notes/) if you want to go deep on buffer overflows, with the specific type in the exam being https://ir0nstone.gitbook.io/notes/types/stack/reliable-shellcode/using-rsp

## Rabbit Holes!

The dreaded rabbit holes. The exam machines almost all (except the buffer overflow) contain some sort of redirection: apps that are not related to the exploit, or apps that have been modified so exploits only partially work.

There is hope! Here are my tips for *recognising* a rabbit hole, so you can stop and take charge:

- you are on a 20 or 25 pt box and it has a website at port 80 with a file named 'creds' in it. Thats pretty obviously a red herring.
- you get access to something and immediately hit a wall: e.g. a database that you get creds to, but once in, the db has no tables of note, and your account has no privileges
- you compromise a website, look it up on exploit db, and it has a exploit-to-root bug on a 20/25 pt box: these boxes require both a local and root flag! Unless you're lucky and the exploit is post the boxes creation, chances are that this exploit wont work; try it, and see if its been blocked
- likewise, just a general exploit that is simple and should work but doesnt: they might have explicitly modified the app or service so the exploit fails and you waste time trying to get it to work
- generally if you spend hours and get nowhere, you are better off doing more enumeration than just beating your head against it. You can always come back later.

## [Virtual Hacking Labs](https://www.virtualhackinglabs.com/)

This is a resource that provides ~50 boot2root machines in a format similar to OSCP. As opposed to regular CTF boot2roots, which might include custom apps, tricks and CTF-like things like steganography, VHL machines like OSCP machines typically involve regular apps and services that due to missing patches or bad configuration are vulnerable.

VHL comes in 1, 2 or 3 month passes. A single 1 month pass is around $99 USD, and if you are near ready for OSCP, you should ideally be able to do all machines within that month.

How do these compare directly to the exam? They are, admittedly, easier. Mainly because there are no rabbit holes on these machines, unlike the exam. However, the basic steps involved: enumerate, identity exploits, adapt exploits as necessary, gain local, gain root is a great skill to work on, to get really comfortable with. And you might get lucky and run into software that actually shows up in the exam!

## Report Writing

- The report format offsec provides available when you start the course, with [an example report here](https://www.offensive-security.com/pwk-online/PWK-Example-Report-v1.pdfc), but is a bit lame. I reorganised it so that I had one section per machine, and basically did each section as a writeup.
- For the report you need to document your path in detail. E.g. rather than saying 'via nmap I found an exposed website which had a sqli issue, which I was able to use to get ssh credentials' you would have a section where you run nmap, a small screenshot of the port summary, and a list in the doc of the ports found possibly with highlighting showing which ones were relevant; then a section showing the landing page of the website, the field for SQLi with the error that helped you determine it was vulnerable and a list of the strings you sent to exploit this (find version, find tables, find contents etc) with screenshots as appropriate, then the creds you found and finally proof that you were able to ssh in with this (e.g. a shot if the terminal after ssh-ing in, and running the `id` command
- For each flag you find (local.txt, root.txt and proof.txt or whatever), you need a screenshot showing the output of ifconfig/ipconfig and the contents of the flag via cat/type. If you don't do this (or don't also submit the flag to the exam dashboard) the machine will not count towards your total!

## Blog Posts & Other Guides

his post by MuirlandOracle (one of the TryHackMe creators) was very helpful to me. It re-iterates some of the advice from above and also comes from the perspective of someone who failed once, which can be useful: https://muirlandoracle.co.uk/2020/12/06/oscp-thoughts/
