# Natas

[Natas](http://overthewire.org/wargames/natas/) is a beginner web-security challenge. It has, at time of writing, 33 levels (excluding 0, and with 34 being a 'Thankyou for Playing' message).

As web hacking is less scriptable, the challenge solutions were written in markdown writeups. When I needed to do some custom code to figure things out, I either used the same language as the challenge (e.g. PHP) or a custom F# script.

## Running the F# scripts

You will need the dotnet core SDK installed - I had 2.2 at time of writing. A command-line way to run the scripts is to run `dotnet <path to sdk/fsharp/fsi.exe> <script>`. Alternatively, using a FSharp-friendly IDE or shoving the script code into a dotnet core executable like a console app will also work.