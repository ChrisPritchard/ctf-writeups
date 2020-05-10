# Biohazard

A toy room. However, not solvable without notes. All encryption decription was done with the excellent [cyberchef (by the gchq!)](https://github.com/gchq/CyberChef)

Overall, pretty fun. Learned a bit about gpg, which was nice. Creator's grasp of english isn't the best though :)

## Web server exploration

```
emblem{fec832623ea498e20bf4fe1821d58727} -> secret bar room: rebecca
lock_pick{037b35e2ff90916a9abf99129c8e1837}
music_sheet{362d72deaf65f5bdc63daece6a1f676e}
gold_emblem{58a8c41a9d08b8a4e38d02a4d7ff4843}
blue_jewel{e1d457e96cac640f863ec7bc475d48aa} 
shield_key{48a7a9227cd7eb89f0a062590798cbac}
helmet_key{458493193501d2b94bbab2e727f8db4b}
```

### Room tracking

```
/diningRoom/                                VISITED - with gold emblem: (vigniere cipher using rebecca) there is a shield key inside the dining room. The html page is called the_great_shield_key
/diningRoom/sapphire.html                   VISITED
/teaRoom/                                   VISITED
/artRoom/                                   VISITED - where the map is
/barRoom/                                   VISITED
/barRoom357162e3db904857963e6e0b64b96ba7/   VISITED - requires piano - played
/barRoom357162e3db904857963e6e0b64b96ba7/barRoomHidden.php VISITED
/diningRoom2F/  VISITED: secret message You get the blue gem by pushing the status to the lower floor. The gem is on the diningRoom first floor. Visit sapphire.html
/tigerStatusRoom/                           VISITED - used blue jewel to get message below:
/galleryRoom/                               VISITED - second message below
/studyRoom/                                 VISITED - requires helmet key
/armorRoom/                                 VISITED - requires shield key - visited and got crest 3
/attic/                                     VISITED - requires shield key again - visited and got crest 4
```

## Crests

Pretty much guessed all these with cyberchef. Impressive that it worked first time.

```
crest 1:
S0pXRkVVS0pKQkxIVVdTWUpFM0VTUlk9
Hint 1: Crest 1 has been encoded twice
Hint 2: Crest 1 contanis 14 letters
Note: You need to collect all 4 crests, combine and decode to reavel another path
The combination should be crest 1 + crest 2 + crest 3 + crest 4. Also, the combination is a type of encoded base and you need to decode it
```

base64 > base32: RlRQIHVzZXI6IG

```
crest 2:
GVFWK5KHK5WTGTCILE4DKY3DNN4GQQRTM5AVCTKE
Hint 1: Crest 2 has been encoded twice
Hint 2: Crest 2 contanis 18 letters
Note: You need to collect all 4 crests, combine and decode to reavel another path
The combination should be crest 1 + crest 2 + crest 3 + crest 4. Also, the combination is a type of encoded base and you need to decode it
```

base32 > base58?: h1bnRlciwgRlRQIHBh

```
crest 3:
MDAxMTAxMTAgMDAxMTAwMTEgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTAwMTEgMDAxMDAwMDAgMDAxMTAxMDAgMDExMDAxMDAgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTAxMTAgMDAxMDAwMDAgMDAxMTAxMDAgMDAxMTEwMDEgMDAxMDAwMDAgMDAxMTAxMDAgMDAxMTEwMDAgMDAxMDAwMDAgMDAxMTAxMTAgMDExMDAwMTEgMDAxMDAwMDAgMDAxMTAxMTEgMDAxMTAxMTAgMDAxMDAwMDAgMDAxMTAxMTAgMDAxMTAxMDAgMDAxMDAwMDAgMDAxMTAxMDEgMDAxMTAxMTAgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTEwMDEgMDAxMDAwMDAgMDAxMTAxMTAgMDExMDAwMDEgMDAxMDAwMDAgMDAxMTAxMDEgMDAxMTEwMDEgMDAxMDAwMDAgMDAxMTAxMDEgMDAxMTAxMTEgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTAxMDEgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTAwMDAgMDAxMDAwMDAgMDAxMTAxMDEgMDAxMTEwMDAgMDAxMDAwMDAgMDAxMTAwMTEgMDAxMTAwMTAgMDAxMDAwMDAgMDAxMTAxMTAgMDAxMTEwMDA=
Hint 1: Crest 3 has been encoded three times
Hint 2: Crest 3 contanis 19 letters
Note: You need to collect all 4 crests, combine and decode to reavel another path
The combination should be crest 1 + crest 2 + crest 3 + crest 4. Also, the combination is a type of encoded base and you need to decode it
```

base64 > binary > charcode: c3M6IHlvdV9jYW50X2h

```
crest 4:
gSUERauVpvKzRpyPpuYz66JDmRTbJubaoArM6CAQsnVwte6zF9J4GGYyun3k5qM9ma4s
Hint 1: Crest 2 has been encoded twice
Hint 2: Crest 2 contanis 17 characters
Note: You need to collect all 4 crests, combine and decode to reavel another path
The combination should be crest 1 + crest 2 + crest 3 + crest 4. Also, the combination is a type of encoded base and you need to decode it
```

base58 > charcode: pZGVfZm9yZXZlcg==

### Result

RlRQIHVzZXI6IGh1bnRlciwgRlRQIHBhc3M6IHlvdV9jYW50X2hpZGVfZm9yZXZlcg== | base64: `FTP user: hunter, FTP pass: you_cant_hide_forever`

## FTP

Three images, a gpg encrypted file and a important.txt file (grabbed them all with `mget *`). The important file said:

```
Jill,

I think the helmet key is inside the text file, but I have no clue on decrypting stuff. Also, I come across a /hidden_closet/ door but it was locked.

From,
Barry
```

I guessed steghide, but the hint was hide, comment and walk away: obviously steghide, exiftool and binwalk

steghide with no passphrase on 001-key.jpg revealed key-001.txt, which contained `cGxhbnQ0Ml9jYW`. That base 64 decodes to `plant32_ca`
exiftool on 002-key.jpg revealed `5fYmVfZGVzdHJveV9`
binwalk -e on 003-key.jpg revealed key-003.txt: `3aXRoX3Zqb2x0`

all three base 64 decoded was: `plant42_can_be_destroy_with_vjolt`

I used this with `gpg -d helmet_key.txt.gpg -o helmet_key.txt` to get the key `helmet_key{458493193501d2b94bbab2e727f8db4b}`.

    > note, gpg would not work on the kali box over ssh. on my host machine, it popped a full screen to enter the key, and I am guessing regular ssh onto kali doesnt allow this.
    
## Website again

```
/hidden_closet/             VISITED - revealed SSH password behind a wolf medal T_virus_rules
                                    - also the following cipher: wpbwbxr wpkzg pltwnhro, txrks_xfqsxrd_bvv_fy_rvmexa_ajk
/studyRoom/                 VISITED - revealed a 'sealed book' containing doom.tar.gz
```

extracting the book revealed the ssh username: `umbrella_guest`

## ssh

`ls -lA` revealed `.jailcell` in the home folder, containing `chris.txt`. This contained the name of the traitor and the vignere key for MO disk 1: `albert`

The decoded cipher from the hidden_closet was: `weasker login password, stars_members_are_my_guinea_pig`

`weasker` had full access as a sudoer. `sudo -i` got me access to `/root/root.txt`: 

```
In the state of emergency, Jill, Barry and Chris are reaching the helipad and awaiting for the helicopter support.

Suddenly, the Tyrant jump out from nowhere. After a tough fight, brad, throw a rocket launcher on the helipad. Without thinking twice, Jill pick up the launcher and fire at the Tyrant.

The Tyrant shredded into pieces and the Mansion was blowed. The survivor able to escape with the helicopter and prepare for their next fight.

The End

flag: 3c5794a00dc56c35f2bf096571edf3bf
```