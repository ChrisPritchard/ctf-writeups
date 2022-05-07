# Natas 11

1. Go to [http://natas11.natas.labs.overthewire.org](http://natas11.natas.labs.overthewire.org)
2. Log in with natas11, U82q5TCMMQ9xuFoI3dYX61s7OZD9JKoK=
3. The F# script [natas11exploit.fsx](./natas11exploit.fsx) calculates the correct value to set in the data cookie.
4. Edit and resend the request with data set to the specified value, to expose the password for natas12

Script explanation:

This challenge uses a cookie which controls whether the next level password can be shown. However the cookie value is scrambled using 'XOR' encryption: its json encoded, then xor'd with a hidden secret, then base64 encoded.

Initial cookie with default data is: ClVLIh4ASCsCBE8lAxMacFMZV2hdVVotEhhUJQNVAmhSEV4sFxFeaAw
This cookie is generated from json that looks like: `{"showpassword":"no","bgcolor":"#ffffff"}`
To find the secret we need to base64 decode the cookie value, then 'xor decrypt' it against the json to get the secret.