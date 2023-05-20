# TryHackMe - Red Team Capstone Challenge

This a report covering the complete compromise of the Reserve Bank of Trimento's network, as part of a red team engagement. 

![](./full-compromise.png)

The system was compromised and proof submitted via this interface, on Try Hack Me's platform: https://tryhackme.com/room/redteamcapstonechallenge

Note, that this portal will only remain accessible during the period the network is made available for non-business users on the Try Hack Me platform.

## Objectives

The objective was to penetrate the corporate network, use that to access the banking network, then finally access the internal Swift banking interface and demonstrate impact via authorising a transaction between two accounts.

By doing this, The Reserve will be able to find further issues in their perimeter, and perhaps make informed decisions like separating the corporate network from their banking network for improved security.

## Overview of the attack path taken

The consultant was able to compromise the perimeter of the corporate network by:

- Using a list of usernames and a password policy against an SMTP server, to brute force some valid active directory credentials
- Finding and adapting a corporate VPN file in order to connect to internal work stations
- Enumerating the domain for kerberoastable service accounts, and brute forcing one found to get a service account and password
- Using the expanded rights of the service account to dump secrets from one of the CORP server machines, and finding the password of a different service account with dc sync rights
- Performing a dc sync and getting all user account hashes of the CORP domain, thus being able to propagate to domain admin on the CORPDC domain controller
- Forging a so-called golden ticket with the enterprise admin group SID in order to gain access to the parent THERESERVE root domain as an enterprise admin
- Using enterprise admin rights to log into the BANKDC domain controller in the BANK domain as an admin
- Creating a domain admin in this domain that allowed access to the JMP server with access to the swift.bank.thereserve.loc website
- Performing a dc sync against the BANK domain in order to get hashes of various users, cracking these as needed in order to find saved credentials for Capturer and Approver Swift accounts
- Using this collection of access to create, verify, capture and approve a transaction between two accounts

It is known there are other ways into and around the network, but as this is a red team exercise and not a penetration test, this documentation focuses on the primary path of compromise.

## Tooling

A collection of common tools was used during this engagement.

- Nmap and Rustscan were used for initial perimeter machine recon, finding the common web ports and SSH as well as the common windows ports and smtp ports of the mail server
- FFuF was used to enumerate the web interfaces, finding subdirectories like the images directory on one of the sites that had files with apparent usernames, and the location of the ovpn file
- Burp Suite Professional was used to access the mail server interface, which was running roundmail and could be accessed from the hostname mail.thereserve.loc
- Mentalist was used to generate a password list using the password policy revealed to the consultant
- THC-Hydra was used to brute force the usernames with the password list against SMTP, to get two valid credentials from the Help Desk group
- OpenVPN was used with the discovered ovpn file to gain access to the workstations
- Remmina was used to remote onto these workstations
- The Impacket toolset was used to get the service account SPNs, to perform dc syncs and to dump credentials from registry hives
- Hashcat was used to crack hashes as needed
- A tool called reverse_ssh (more notes on this below) was used to create secure reverse shells, and to facilitate port forwarding and proxies
- proxychains was used to run commands over established socks proxies
- evil-winrm was used in some cases to establish temporary shells on machines via user hashes, and to upload/download files
- mimikatz was used to craft a golden ticket for access to the RootDC
- PsExec was used to gain access to the RootDC with the golden ticket


On top of these custom tools, from the windows machines themselves reg was used to save registry hives, powershell was used to do some AD enumeration and to generally run commands, and chrome was used later in the engagement to access the Swift interface - notably Chrome had saved credentials for several Approver users which provided access as that role.

### Reverse_SSH

This tool is considerably less well known than the others, being built by a former colleague of the consultant. It is written in Go, and generally evades AntiVirus detection by things such as Defender, making it a useful way to access a network without having to worry about evasion: https://github.com/NHAS/reverse_ssh

The basic premise of the tool is that:

- you start a server on your attack box
- on a target, you upload a client binary via whatever means and run it with an argument pointing back at the server

This will create a 'client connection', with a long guid as an ID that doubles as a server host key. At this point, via using the server as a jumphost, the target can be connected to over normal SSH. E.g. if the server is running locally at port :3232, and the target's ID is something like `[LONGID]`, then a SSH connection can be established to the target via `ssh -J localhost:3232 [LONGID]`. This works even if the target is not running SSH, as reverse_ssh implements fully the SSH protocol this means you can also use SCP with it for copying files, -D to create socks proxies, -R for remote port forwarding etc.

In this environment, not only was this used to create stable reverse shells on the foothold machines, but by remote forwarding the server port and uploading the client deeper in the network, increasingly stretched connections could be made from the inner segregated systems all the way back to the attack box. Then by establishing proxies via `-D 9050` to different targets, access to for example the swift interface from the attack box was possible.

In this fashion, reverse_ssh served as a sort of micro C2 framework.

## Stage 1: OSINT of the external interfaces, and getting a foothold

## Stage 2: Compromising the CORP Domain

## Stage 3: Compromising the Forest via the Root DC

## Stage 4: Access to the Swift system and demonstrating impact

## Summary & Recommendations

Overall, the network's largest failing were weak password policies. Via a small list of about 720 options, it was possible to brute force two initial points of access. Then via bruteforcing another weak password in a service principle, admin access to the non-dc machines in the CORP network was obtained. Everything that followed in the compromise stemmed from this original path of attack.

In addition to fully segregating the banking network from the internet, by removing it from the forest that contains the corporate network, the consultant recommends that passwords be fully random and not based on a small set of word options and rules. Users should all have passwords at least 14 characters long (with or without complexity), randomly generated using a secure random algorithm, and stored in each user's password manager.

Beyond password policy, the only other significant failing was that the Approver users of the swift system had saved their credentials in their browsers. By gaining access to their workstations, these passwords could be recovered from Chrome without effort. Again, keeping the password long and in a password manager would be a more secure approach.
