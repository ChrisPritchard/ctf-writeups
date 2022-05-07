open System
open System.Text
open System.IO

let dictionary = File.ReadAllLines "./Krypton/dictionary.txt"
let englishFrequencyOrder = "eatsorinhcldupgfwymbkvjxqz".ToUpper().ToCharArray ()

let b64decode s =
    let bytes = Convert.FromBase64String s
    Encoding.ASCII.GetString bytes

let minA = int 'A'
let maxZ = int 'Z'

let rot n (s: string) =
    let buffer = s.ToCharArray()
    for i in [0..buffer.Length - 1] do
        buffer.[i] <-
            let c = int buffer.[i]
            if c < minA || c > maxZ then buffer.[i]
            else
                let rotated = c + n
                let bound = 
                    if rotated > maxZ 
                    then rotated - 26 
                    elif rotated < minA 
                    then maxZ - (minA - (rotated + 1))
                    else rotated
                char bound
    String(buffer)

let freqDecode sources (cipher: string) =
    let sourcesFrequencyOrder = 
        (sources |> Seq.map File.ReadAllText |> String.concat "").Replace(" ", "")
        |> Seq.countBy id |> Seq.sortByDescending snd |> Seq.map fst |> Seq.toArray
    cipher.Replace(" ", "").ToCharArray ()
    |> Array.map (fun c -> 
        let index = Array.findIndex ((=) c) sourcesFrequencyOrder
        englishFrequencyOrder.[index])
    |> String

let rec isEnglish (s: string) =
    let (fullMatches, partialMatches) =
        dictionary
        |> Array.filter s.Contains
        |> Array.map (fun word -> s.Replace(word, ""))
        |> Array.partition ((=) "")
    if fullMatches.Length = 0 && partialMatches.Length = 0 then false
    elif fullMatches.Length > 0 then true
    else Array.exists isEnglish partialMatches

let vigenereDecode (key: string) (cipher: string) =
    cipher.Replace(" ", "").ToCharArray() 
    |> Array.mapi (fun i c ->
        let keyChar = int key.[i % key.Length] - minA
        rot -keyChar (string c) |> char)
    |> String

let vigenereKeylength source =
    let cipherText = (File.ReadAllText source).Replace (" ", "")
    let repeats =
        cipherText
        |> Seq.windowed 3
        |> Seq.map String
        |> Seq.countBy id
        |> Seq.filter (snd >> (<) 1)
        |> Seq.map fst
        |> Seq.toArray 
    let rec gaps (cipherText: string) found (repeat: string) =
        let start = cipherText.IndexOf(repeat)
        if start = -1 then found
        else
            let next = cipherText.[start + 1..].IndexOf(repeat)
            if next = -1 then found
            else
                let newFound = (next + 1)::found
                gaps (cipherText.[start + next + 1..]) newFound repeat
    let factors n = 
        [3..n/2] 
        |> List.filter (fun on -> n % on = 0)
    let allFactors =
        repeats 
        |> Seq.collect (gaps cipherText []) 
        |> Seq.collect factors
        |> Seq.toArray
    allFactors
    |> Seq.groupBy id
    |> Seq.map (fun (factor, col) -> factor, Seq.length col)
    |> Seq.groupBy snd
    |> Seq.sortByDescending fst
    |> Seq.take 3 |> Seq.collect (snd >> Seq.map fst)
    |> Seq.toList

let vigenereHack source keyLength (cipher: string) =
    let subStrings source =
        (File.ReadAllText source).Replace (" ", "")
        |> Seq.indexed
        |> Seq.groupBy (fun (i, _) -> i % keyLength)
        |> Seq.map (snd >> Seq.map snd >> Seq.toArray >> String)
    let isLikely keyChar (subString: string) = 
        rot -(int keyChar - minA) subString 
        |> Seq.countBy id
        |> Map.ofSeq
        |> fun m -> m.ContainsKey 'E' && float m.['E'] / float subString.Length >= 0.10
    let candidates subString =
        ['A'..'Z'] |> List.filter (fun c -> isLikely c subString)
    let allCandidates source =
        source |> subStrings |> Seq.map candidates |> Seq.toList
    let rec keyPossibles candidates soFar =
        match candidates with
        | [] -> [soFar]
        | cl::tail ->
            cl |> List.collect (fun c -> keyPossibles tail (soFar + string c))
    keyPossibles (allCandidates source) ""
    |> Seq.map (fun key -> vigenereDecode key cipher)
    |> Seq.filter isEnglish |> Seq.distinct |> Seq.toList
    
// Krypton 0:
printfn "Krypton 1: %s" <| b64decode "S1JZUFRPTklTR1JFQVQ="

// Krypton 1:
printfn "Krypton 2: %s" <| rot 13 "YRIRY GJB CNFFJBEQ EBGGRA"

// Krypton 2:
printfn "Krypton 3: %s" <| rot -12 "OMQEMDUEQMEK"

// Krypton 3:
let sources3 = ["./Krypton/krypton03found/found1"; "./Krypton/krypton03found/found2"; "./Krypton/krypton03found/found3"]
printfn "Krypton 4: %s" <| freqDecode sources3 "KSVVW BGSJD SVSIS VXBMN YQUUK BNWCU ANMJS"

// Krypton 4:
let sources4 = ["./Krypton/krypton04found/found1"; "./Krypton/krypton04found/found2"]
printfn "Krypton 5 options: %A" <| vigenereHack sources4.[0] 6 "HCIKV RJOX"

// Krypton 5:
let sources5 = ["./Krypton/krypton05found/found1"; "./Krypton/krypton05found/found2"; "./Krypton/krypton05found/found3"]
let keyLengthOptions = vigenereKeylength sources5.[1]
let plainTextOptions = keyLengthOptions |> List.collect (fun kl -> vigenereHack sources5.[0] kl "BELOS Z")
printfn "Krypton 6 options: %A" plainTextOptions

// Krypton 6:
let chosenCipherText = File.ReadAllLines "./Krypton/krypton6chosenCiphertext"
let plainText = 
    "PNUKLYLWRQKGKBE".ToCharArray () 
    |> Array.mapi (fun i c -> 
        chosenCipherText 
        |> Array.find (fun s -> s.[i + 2] = c)
        |> fun s -> s.[0])
    |> String
printfn "Krypton 7: %s" plainText