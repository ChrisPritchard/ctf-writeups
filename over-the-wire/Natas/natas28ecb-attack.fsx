open System
open System.Net

let url = "http://natas28.natas.labs.overthewire.org/"
let credentials = "natas28:JWwR438wkgTsNKBbcJoowyysdM82YjeF"
let basicAuth = "Authorization: Basic " + Convert.ToBase64String (Seq.toArray (Seq.map byte credentials)) 

let hex (bytes: seq<byte>) =
    bytes
    |> Seq.map (fun b -> Convert.ToString(b, 16).PadLeft(2, '0'))
    |> String.concat ""

let b64tohex s =
    Convert.FromBase64String(s) |> hex

let oracle (query: string) =
    let url = sprintf "%s?query=%s" url (WebUtility.UrlEncode(query))
    let http = HttpWebRequest.CreateHttp url
    http.Headers.Add(basicAuth)
    http.Method <- "HEAD"
    http.AllowAutoRedirect <- false

    let response =
        try
            http.GetResponse ()
        with | :? WebException as webEx ->
            webEx.Response
    let newUrl = response.Headers.["Location"]
    let query = WebUtility.UrlDecode(newUrl.Substring(newUrl.IndexOf("query=") + 6))
    b64tohex query

let blockSize = 
    let baseSize = oracle ""
    let atSize8 = oracle "AAAAAAAA"
    if atSize8.Length > baseSize.Length then 8
    else
        let atSize16 = oracle "AAAAAAAAAAAAAAAA"
        if atSize16.Length > baseSize.Length then 16
        else failwith "something is wrong"

printfn "blocksize: %i" blockSize

let chunked (hex: string) =
    Seq.chunkBySize (blockSize * 2) hex
    |> Seq.map (fun ca -> String(ca))
    |> Seq.toArray

let offsetSize, repeatBlock = 
    [0..blockSize * 2 - 1] 
    |> List.pick (fun n ->
        let query = String.replicate n "x" + String.replicate (blockSize * 2) "y"
        let chunks = oracle query |> chunked
        if Set.count (Set.ofArray chunks) = chunks.Length then None
        else 
            let index = [1..chunks.Length - 1] |> List.find (fun i -> chunks.[i] = chunks.[i-1])
            Some (n, index))
    
printfn "offset: %i" offsetSize
let offset = String.replicate offsetSize "x"

let rec extractor (soFar: string) =
    let staticSize = (blockSize * 2 - soFar.Length) - 1
    let query = offset + String.replicate staticSize "y"
    let target = (oracle query |> chunked).[repeatBlock]
    let nextChar =
        [32..126]
        |> List.map (char >> string)
        |> List.tryFind (fun c -> 
            let guess = query + soFar + c
            let result = (oracle guess |> chunked).[repeatBlock]
            target = result)
    match nextChar with
    | Some c ->
        let nextSoFar = soFar + c
        printfn "Found %s" nextSoFar
        if nextSoFar.Length = blockSize * 2 then ()
        else extractor nextSoFar
    | None -> 
        printfn "unable to find further chars (possibly url input escaped on server)"

extractor ""