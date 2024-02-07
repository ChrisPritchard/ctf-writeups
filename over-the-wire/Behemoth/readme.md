# Behemoth

Reasonably fun exploit challenges, especially since these days reversing the binaries with ghidra is pretty effective to find out what is required.

When I came back and solved these in 2024, I built a project to solve all the levels one after the other in Rust, which can be found here: https://github.com/ChrisPritchard/behemoth

Difficulties were mainly in behemoth1, which I found a real struggle. This was mainly due to the box being updated since the first time I tried it, with no more python2, no jmp esps in libc, and no more sh preserving suid bits by default.

On top of that, I didn't appreciate how python3 is different for printing bytes - I ended up putting together a helper doc mainly for behemoth1 alone, found here: [GDB-TIPS-AND-TRICKS](../../GDB-TIPS-AND-TRICKS.md)

Other than that though, mostly smooth sailing! Had to relearn how to do format bugs for one challenge, which was fun, but the rest were fairly trivial.

> NOTE: my old attempts can be found under the [old](./old/) folder. I only made it to behemoth3 back then, and behemoth1 was far simpler with a basic ret2libc