# Kioptrix: 1

https://www.vulnhub.com/entry/kioptrix-level-1-1,22/

Recommended as an OSCP-like VM here: https://www.abatchy.com/2017/02/oscp-like-vulnhub-vms

## Setup

I had tried this one before, but had failed to get it to work. Not even able to get it to run. Not sure entirely what I fixed to get it running this time, but I'll document the steps in case they're helpful.

I use virtualbox on Windows 10. I tend to do vulnhub VMs by running the VM in one instance and Kali next to it in another. My windows PC is a beast, and so I have no issue running these VMs performance or space wise.

1. Kioptrix: 1 is a VMWare VM. It comes down in a .rar, which I extracted, revealing a VMDK file.
2. I create a new VM in virtual box (normally I import the .ova, not possible here), and select the VMDK as the harddrive
3. For network settings, I set both Kali and the Kioptrix VM to use Host only
4. Additionally, I changed the hardware for the Kiptrix VM from the default `Intel PRO/1000 MT Desktop (82540EM)` to `PCnet-PCI II (Am79C970A)`

This last step seemed to be the key - before that, no matter what I did, I could not find Kioptrix on the network. The host only step is probably unnecessary - I just needed to switch to it to absolutely confirm Kioptrix was not coming up. My home network is a bit noisy, so bridged (which is what I normally use) wasn't making Kioptrix's absence clear.

## Recon

Nmap -p- reveals:

```
PORT      STATE SERVICE
22/tcp    open  ssh
80/tcp    open  http
111/tcp   open  rpcbind
139/tcp   open  netbios-ssn
443/tcp   open  https
32768/tcp open  filenet-tms
```

