# Natas 06

1. Go to [http://natas6.natas.labs.overthewire.org](http://natas6.natas.labs.overthewire.org)
2. Log in with natas6, aGoY4q2Dc6MgDq4oL4YtoKtyAg9PeHa1
3. This page checks for a password, and has a link to the source code.
4. Viewing the source, the secret that the user input is checked against is stored in includes/secret.inc
5. Nav to includes/secret.inc and view source to see the secret check code
6. Return to the form and use the secret to get the secret for natas7