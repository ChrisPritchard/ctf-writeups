# Natas 18

To see the site:

1. Go to [http://natas18.natas.labs.overthewire.org](http://natas18.natas.labs.overthewire.org)
2. Log in with natas18, xvKIqDjy4OPv7wCRgDlmj0pFsCsDjhdP

To get the password: Run the script [natas18exploit.fsx](./natas18exploit.fsx) to get the password for natas19. This logs in to the site itself. Note, this will take a few minutes.

Explanation: This site uses PHP sessions, but suffers from an issue called 'session fixation': i.e., you can set the session id, and if that session already exists, you get its rights. In this case session 119 was active with an admin flag. I figured this out from reading this exploit issue report: [https://www.php.net/manual/en/session.security.php](https://www.php.net/manual/en/session.security.php)