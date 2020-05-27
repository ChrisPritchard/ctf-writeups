# vulnhub-and-tryhackme-writeups

Write-ups of the vulnhub VMs and TryHackMe rooms of interest I have done.

I work as a security consultant for Aura infosec in wellington, where my role is primarily defensive/advisory/analysis related. Hacking is handled by our pentesters, but I want to learn it as well. My background however is primarily software development (as can be seen in my other repos on github), and on windows at that, so my hacking skills started from basically zero.

In that vein, amongst many other resources (over the wire, tonnes of books etc), vulnhub is a great resource! And really fun, too. The actual experience of hacking against an otherwise opaque box, learning different techniques for all the stages of a compromise, is amazing.

The writeups are numbered in the order I did them.

## TryHackMe

I registered with TryHackMe after watching [a video by John Hammond](https://www.youtube.com/watch?v=xl2Xx5YOKcI). Its chief draw for me are its paths - curated sets of 'rooms' towards a specific level of competency - and its provided online virtual network with online virtual machines.

The latter is awesome: running virtual box kali on my home network is not too stable, and different vms for vulnhub often have different network configurations, meaning I was constantly wrangling with the network structure. TryHackMe handles all that, in addition providing a nice disposable Kali vm on demand (if you have registered).

Note for TryHackMe: on windows the site recommends an OpenVPN client to install. I have had, over several machines, much better success with the [OpenVPN *Connect* Client](https://openvpn.net/client-connect-vpn-for-windows/). Just seems to work better.