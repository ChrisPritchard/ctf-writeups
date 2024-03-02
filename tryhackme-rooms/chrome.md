# Chrome

https://tryhackme.com/room/chrome, rated Hard

Not too tricky a room, really, though the last step (which gives four of the answers, but only two if it doesnt work) requires a bit of OOTB thinking.

Note for readers, I used my Windows machine for this room. Some tools you would use are different on Linux, but I'm told its possible.

1. You are giving a zip file called `chromefiles`, which contains a pcap. Open the pcap in Wireshark where you will see a lot of SMB traffic.
2. You can export the files involved using wireshark's 'Export Objects', which will reveal two files (one of which is spread over a few objects): `encryptedfiles` and `transfer.exe`.
3. A quick look at transfer will show its a .NET executable (just using `strings` will show common .NET text). Use [dnSpy](https://github.com/dnSpy/dnSpy) to open it. Browsing to the Program class (which holds a main function in dotnet) you can see the AES encryption operation that created the `encryptedfiles` file.
4. I used [CyberChef](https://gchq.github.io/CyberChef/) to decrypt the file: load it in as the input file, use AES Decrypt as the operation, add in the keys from the dotnet program as key and IV (remember to set format to UTF8), set input and output as Raw. The mode should be the default, CBC. If it doesn't decrypt properly, try re-exporting the specific encrypted file from wireshark. The result of the raw data, as seen by the 'PK' it starts with, is a zip file. CyberChef will already know this: if you download the output it will prompt a filename of download.zip.
5. Inside the zip file is an AppData folder, basically the config and settings of a windows user (usually its hidden inside their profile folder). Given the room is named 'Chrome' and we are looking for urls and passwords, presumably we need to get access to Chrome's saved passwords, which will be in the AppData folder.

The following steps are done with [mimikatz](https://github.com/ParrotSec/mimikatz), a windows tool. Windows uses the Data Protection API (DPAPI) to protect secrets, and the master key is within AppData. We can extract this as a crackable hash for use with john the ripper, using the following:

```
DPAPImk2john -mk AppData/Roaming/Microsoft/Protect/S-1-5-21-3854677062-280096443-3674533662-1001/8c6b6187-8eaa-48bd-be16-98212a441580 -S S-1-5-21-3854677062-280096443-3674533662-1001 -c local
```

`DPAPImk2john` is part of john's set of conversion scripts. In the above, `S-1-5-21-3854677062-280096443-3674533662-1001` is the SID of the user (there is only one). And the guid after that is just the name of the secrets file.

The resulting hash can then be cracked with john and rockyou, and will swiftly reveal the password for the master key, as well as the first answer the room requires.

With the password to the master key, you can load it into mimikatz with the following command:

```
dpapi::masterkey /in:"\AppData\Roaming\Microsoft\Protect\S-1-5-21-3854677062-280096443-3674533662-1001\8c6b6187-8eaa-48bd-be16-98212a441580" /sid:S-1-5-21-3854677062-280096443-3674533662-1001 /password:[redacted] /protected
```

Finally, with this, you can get the chrome secrets: 

```
dpapi::chrome /in:"\AppData\Local\Google\Chrome\User Data\Default\Login Data" /unprotect /state:"\AppData\Local\Google\Chrome\User Data\Local State"
```

But wait! If you try this, most likely you will get the two URLs you need, but decrypting the passwords will fail with an error ('kuhn...' something). The solution can be found by looking at the actual source file (this isn't the first error I've found with mimikatz): https://github.com/gentilkiwi/mimikatz/blob/master/mimikatz/modules/dpapi/packages/kuhl_m_dpapi_chrome.c#L255. It helps that there is a typo in the error messages, with the failure returning `fond` not `found`, allowing you to trace the fault. The issue is its looking for `"\"os_crypt\":{\"encrypted_key\":\""` in the `local state` file., but if you check this yourself, you will see `os_crypt` has two keys, and the `encrypted_key` is the second of these, the first being `app_bound_fixed_data`. To fix this, just open local state and move the keys around so encrypted key and its value is first.

Running the command above will now print the passwords. If you like, vote for my PR to fix this (I'm not sure anyone is even maintaining mimikatz, but still :): https://github.com/gentilkiwi/mimikatz/pull/435
