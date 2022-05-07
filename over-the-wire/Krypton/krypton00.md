# Krypton 0

> Welcome to Krypton! The first level is easy. The following string encodes the password using Base64:
>
> S1JZUFRPTklTR1JFQVQ=
>
>Use this password to log in to krypton.labs.overthewire.org with username krypton1 using SSH on port 2222. You can find the files for other levels in /krypton/

In F#:

```fsharp
open System
open System.Text

let bytes = Convert.FromBase64String("S1JZUFRPTklTR1JFQVQ=")
printfn "%s" <| Encoding.ASCII.GetString(bytes)
```

Result: `KRYPTONISGREAT`