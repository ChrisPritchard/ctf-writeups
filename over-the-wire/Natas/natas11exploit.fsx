open System

let encoded = "ClVLIh4ASCsCBE8lAxMacFMZV2hdVVotEhhUJQNVAmhSEV4sFxFeaAw="
let json = "{\"showpassword\":\"no\",\"bgcolor\":\"#ffffff\"}"
let targetJson = "{\"showpassword\":\"yes\",\"bgcolor\":\"#ffffff\"}"

let base64Decode s = System.Convert.FromBase64String s |> Array.map char |> fun sa -> String (sa)
let base64Encode (s: string) = s.ToCharArray() |> Array.map byte |> System.Convert.ToBase64String

let xor (inData: string) (key: string) =
    inData.ToCharArray ()
    |> Array.mapi (fun i c ->
        char (byte c ^^^ byte key.[i % key.Length]))
    |> fun sa -> String (sa)

let secret = xor json (base64Decode encoded)

let test1 = base64Encode (xor json secret)

let secret2 = "qw8J"

let test2 = base64Encode (xor json secret2)

let solvedCookieValue = base64Encode (xor targetJson secret2)