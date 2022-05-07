# Natas 10

1. Go to [http://natas10.natas.labs.overthewire.org](http://natas10.natas.labs.overthewire.org)
2. Log in with natas10, nOpp1igQAkUzaI1GUUjzn1bFVj7xCNzu
3. This is the same as the previous challenge, but `;`, `/` and `&` are checked for in the input before it is injected, so we can't cancel the grep like last time to execute our own commands after.
4. Instead use the grep to read the password file: Just go through random letters until you find one inside the password file. E.g.: `c /etc/natas_webpass/natas11 #` (a and b are not in the passfile). The pass for 11 will be printed in the results area.
