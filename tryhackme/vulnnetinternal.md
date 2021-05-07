# VulnNet: Internal

https://tryhackme.com/room/vulnnetinternal

A fun room, as are all the rooms in the vulnnet series! This one covered a bunch of different services.

1. A scan with rustscan -sV revealed the following:

  ```
  22/tcp    open  ssh         syn-ack OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
  111/tcp   open  rpcbind     syn-ack 2-4 (RPC #100000)
  139/tcp   open  netbios-ssn syn-ack Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
  445/tcp   open  netbios-ssn syn-ack Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
  873/tcp   open  rsync       syn-ack (protocol version 31)
  2049/tcp  open  nfs_acl     syn-ack 3 (RPC #100227)
  6379/tcp  open  redis       syn-ack Redis key-value store
  35611/tcp open  nlockmgr    syn-ack 1-4 (RPC #100021)
  38239/tcp open  java-rmi    syn-ack Java RMI
  38761/tcp open  mountd      syn-ack 1-3 (RPC #100005)
  46045/tcp open  mountd      syn-ack 1-3 (RPC #100005)
  58115/tcp open  mountd      syn-ack 1-3 (RPC #100005)
  ```

  So, ssh, smb, rsync, nfs and redis, basically.

2. Samba was first: smbclient enumerated the shares, and then allowed access to the sole share accessible anonymously. Under there I found the 'service flag', but otherwise this was empty.

3. Redis and Rsync both required passwords, so I had to ignore them initially.

4. showmount -e for nfs revealed an /etc/conf folder, which I mounted. In there were a number of config files, including redis.conf which gave me the redis password.

5. In redis (accessed via the redis-cli) I ran KEYS * to reveal the 'internal flag' key, getting me the second flag.

6. There was another key, authlist, that when I queried it showed a selection of identical base64 strings. Decoding one of these gave me the rsync username and password.

7. Using `rsync -av rsync://rsync-connect@ip/files .` I was able to download what was apparently the 'sys-internal' user's home folder, which gave me the user flag. I generated a ssh key, then used rsync to send it via `rsync -v ~/.ssh/id_rsa.pub rsync://rsync-connect@ip/files/sys-internal/.ssh/authorized_keys`, which allowed me to ssh in as sys-internal.

8. On the box, the one thing that stood out was a `/TeamCity` installation. In there, under /logs, was a catalina.out log file I could read. At the end of this was a super user authentication token.

9. To access the TeamCity interface I used chisel, forward port 8111 to my attack box so I could access it. I logged in using the super user token as the password with a blank username.

10. Once in, escalation to root could be done a number of ways. I did it by creating a new project, adding a single build step of type 'command line' to that project, with the step copying sh to the sys-internal home directory and setting its suid bit. This allowed me to read the root flag.

A nice trail of bread crumbs with this room :)
