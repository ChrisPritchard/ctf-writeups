# Behemoth 0

This can be solved just by doing an ltrace when running the binary (`/behemoth/behemoth0`), where the strcmp with the valid password is clearly visible.

Once you have a shell, grab the password for behemoth1 from `/etc/behemoth_pass/behemoth1`; you will need to disconnect from the ssh session and log back in with behemoth1 and this password (`su` doesn't work for some reason).
