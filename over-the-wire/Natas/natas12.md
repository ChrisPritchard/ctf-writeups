# Natas 12

1. Go to [http://natas12.natas.labs.overthewire.org](http://natas12.natas.labs.overthewire.org)
2. Log in with natas12, EDXp0pS26wLKHZy1rDBPUZk0RKfLGIR3
3. On this page a file upload box is presented, that will stick a file into an accessible location on the server. The file name is coded to be random, with a jpeg extension. However, the extension is defined inside a hidden field.
4. Using inspect or dev tools, find the hidden field and change the extension to .php
5. Then upload the [natas12exploit.php](./natas12exploit.php) file in this repo. This contains a exec cat command to read natas13's password.
6. Once uploaded, follow the link to see the password.