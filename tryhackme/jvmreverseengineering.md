# JVM Reverse Engineering

https://tryhackme.com/room/jvmreverseengineering

Not a challenge room, per se, but the final two tasks were really hard so a quick writeup. Only on task 6 & 7 - the other five can be breezed through, especially with basic tools like javap and [jd-gui](https://github.com/java-decompiler/jd-gui).

## Task 6 - Advanced String Obfuscation 

'BasicStringObfuscation' is the name of the jar file, even though the task is named Advanced String Obfuscation. This jar file will open with jd-gui, but has obviously been heavily obfuscated: for example, the first line starts with `if (paramArrayOfString.length >= ((int)1506594314L ^ 0x59CCCE0B)) {`, checking if there is 1 parameter, and it all goes down hill from there.

I tried a few de-obfuscation tools, without luck, so knuckled down. What I saw what there were strings stored within that were scrambled, unscrambled by a method named `1.a` which took two parameters: the first was an index into the scrambled string array (though doubled, e.g. '4' meant position 8 in the array) and the second parameter was part of the de-scrambling process. I identified several sets of params: 

- `2, 2` was the 'correct' message, 
- `3, 38` 'incorrect', 
- `4, 87` the default 'please supply a param' and 
- `0, 100` the password I was looking for, but it was wrapped by a method called `c`. 

However, I couldn't reverse engineer the scrambling - tbh, I suspect jd-gui had mangled the function code, so the task was impossible this way.

Looking around, I found a decompiler that went straight from jar or class to bytecode, rather than attempting to form valid java: [Krakatau](https://github.com/Storyyeller/Krakatau). This was great: I ran this as `python Krakatau/disassemble.py -out disassembled.zip -roundtrip BasicStringObfuscation.jar` and I got three `.j` files, 0, 1 and 2, which contained pure bytecode (basically java assembly). Furthermore, I could take these and then run `python Krakatau/assemble.py -out result.jar -r disassembled/` to get a working jar file.

  Well, sort of; `java -jar result.jar` would fail with `Error: Invalid or corrupt jarfile result.jar`, however `java -cp result.jar 0` (`0` is the class file containing `main`) would work.
  
Opening `0.j` I walked through the code. What I could see was those numbers from above in a form like:

```
L72:    iconst_3 
L73:    bipush 38 
L75:    invokestatic [15] 
```

Basically, the above is `1.a(3, 38)`. Further analysis showed that a line like `L91:    invokevirtual [48] ` was basically println. From this I tracked down that final 'please supply a password' message, for when no argument is provided. I simply changed it from `iconst_4`, `bipush 87`, to `0` and `100` and boom! Running the re-assembled jar file printed out a string of password-like characters. 

However, this failed when I submitted it. Going back to the jd-gui interface, I remembered the password is actually further mutated with a function called `c`, that appeared to do some complicated xoring. Looking at the bytecode, I could see this as `invokestatic [30]`. So... what if I modified the final command from:

```
L85:    iconst_1 
L86:    bipush 95
L88:    invokestatic [15]
L91:    invokevirtual [48] 
```

to:

```
L85:    iconst_1 
L86:    bipush 95
L88:    invokestatic [15]
L89:    invokestatic [30] 
L91:    invokevirtual [48] 
```

? 

I ran this and got a different string, which worked :)

## Task 7 - Extreme Obf 

This one was a bit trickier, and stumped me for a bit. Basically because opening it with jd-gui would result in obviously only partially parsed java files (perhaps entirely false java files, placed to confound jd-gui), and Krakatau would crash trying to decompile the jar file. In fact, jar files being just zip files, in theory I should have been able to abstract 'BasicStringObfuscation.jar' (yes it had the same name again) with just 7zip or what have you, but this would fail too: it was a corrupted zip file. But one which still worked fine if ran via `java -jar`?

I eventually figured out a way past this; my thinking was the file must be valid but padded or twisted in such a way it couldn't be treated as a normal zip. So I ran binwalk against it, which sure enough showed a fairly regular zip file and then some absurd padding and/or comments. `binwalk -e` got me the pure class files.

After this, Krakatau as before got me bytecode, and I could recompile this and run it just as in the last task. However the bytecode itself was heavily obfuscated: almost every third line would include a `goto` call, like so: 

```
L324:   iconst_3 
L325:   bipush 95 
L327:   goto L331 

        .stack stack_1 Object java/lang/Throwable 
L330:   athrow 

        .stack full 
            locals Object [Ljava/lang/String; Object java/lang/String 
            stack Object java/io/PrintStream Integer Integer 
        .end stack 
L331:   invokestatic Method '1' a (II)Ljava/lang/String; 
L334:   goto L338 

        .stack stack_1 Object java/lang/Throwable 
L337:   athrow 

        .stack full 
            locals Object [Ljava/lang/String; Object java/lang/String 
            stack Object java/io/PrintStream Object java/lang/String 
        .end stack 
L338:   goto L342 
```

And function names were harder to understand, e.g. `invokestatic Method '1' a (II)Ljava/lang/String; `. However, what was lucky, is that the same principle applied - in the above snippet, you can see `L324:   iconst_3` and `L325:   bipush 95`, signifying a call to the string retriever. This only occurred six times in the massive byte code. Through trial and error, I was able to determine that `4, 42` was the 'please provide a password' string, and thus our target position, while `1, 77` retrieved the scrambled password. I put the password in the right position and got the scrambled characters, so I figured the overall function worked the same.

The next step was to find the function that served as the `c` function, the unscrambler of the password. This was a bit tricky: along with the gotos, there were plenty of stack frames, pointless xor operations and switches in the byte code to obscure what was happening. But, following from the original `1, 77`:

```
L162:   iconst_1 
L163:   bipush 77 
L165:   goto L169 
```

```
invokestatic Method '1' a (II)Ljava/lang/String; 
L172:   goto L176 
```

(the above invoke static was equivalent to the `1.a` function from the previous task, and common across the other bipushes)

```
L176:   getstatic Field c '1' I 
L179:   ifle L187 
L182:   ldc 730770734 
L184:   goto L189 
```

```
L189:   ldc -1822908253 
L191:   ixor 
L192:   lookupswitch 
            -1193931379 : L187 
            -225155977 : L220 
            default : L426 
```

```
L220:   goto L224
```

```
L224:   invokestatic Method '0' c (Ljava/lang/String;)Ljava/lang/String; 
L227:   goto L231 
```

finally. The above `invokestatic` was what I needed. Returning to the final bipush I had changed:

```
L353:   iconst_1 
L354:   bipush 77
L356:   goto L360 
```

```
L360:   invokestatic Method '1' a (II)Ljava/lang/String; 
L363:   goto L367 
```

I modified the above with

```
L360:   invokestatic Method '1' a (II)Ljava/lang/String; 
L361:   invokestatic Method '0' c (Ljava/lang/String;)Ljava/lang/String; 
L363:   goto L367 
```

Recompiled and boom, I got the unscrambled password :)
