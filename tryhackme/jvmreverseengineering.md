# JVM Reverse Engineering

https://tryhackme.com/room/jvmreverseengineering

Not a challenge room, per se, but the final two tasks were really hard so a quick writeup. Only on task 6 & 7 - the other five can be breezed through, especially with basic tools like javap and [jd-gui](https://github.com/java-decompiler/jd-gui).

## Task 6

'BasicStringObfuscation' is the name of the jar file, even though the task is named Advanced String Obfuscation. This jar file will open with jd-gui, but has obviously been heavily obfuscated: for example, the first line starts with `if (paramArrayOfString.length >= ((int)1506594314L ^ 0x59CCCE0B)) {`, checking if there is 1 parameter, and it all goes down hill from there.

I tried a few de-obfuscation tools, without luck, so knuckled down. What I saw what there were strings stored within that were scrambled, unscrambled by a method named `1.a` which took two parameters: the first was an index into the scrambled string array (though doubled, e.g. '4' meant position 8 in the array) and the second parameter was part of the de-scrambling process. I identified several sets of params: 

- 2, 2 was the 'correct' message, 
- 3, 38 'incorrect', 
- 4, 87 the default 'please supply a param' and 
- 0, 100 the password I was looking for, but it was wrapped by a method called `c`. 

However, I couldn't reverse engineer the scrambling - tbh, I suspect jd-gui had managed the function code, so the task was impossible this way.

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

? I ran this and got a different string, which worked :)

## Task 7
