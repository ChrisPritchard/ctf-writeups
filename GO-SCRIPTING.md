# Go Scripting guide

as an alternative to python or ruby, go scripting is quick and clean.

after creating a .go file, `go run <script>.go` will invoke it.

samples taken from a webmin exploit, and my xss hunter cleaner script.

## Making web requests

set the imports (not all are needed based on scenario) and create a client:

```go
import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
)

var client = &http.Client{}
```

set to the burp proxy:

```go
proxyUrl, _ := url.Parse("http://127.0.0.1:8080")
client.Transport = &http.Transport{Proxy: http.ProxyURL(proxyUrl)}
```

disable 302 following:

```go
client.CheckRedirect = func(req *http.Request, via []*http.Request) error {
    return http.ErrUseLastResponse
}
```

make a get request:

```go
url := fmt.Sprintf("%s/file/show.cgi/bin/%s|%s|", webminUrl, "12345", command)
req, _ = http.NewRequest(http.MethodGet, url, nil)
req.Header.Add("Cookie", "testing=1; sid="+sid)

resp, _ = client.Do(req)
```

make a post/put/etc request with a string body (and cookies):

```go
data := strings.NewReader("page=%2F&user=" + username + "&pass=" + password)
req, _ := http.NewRequest(http.MethodPost, webminUrl+"/session_login.cgi", data)
req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
req.Header.Add("Cookie", "testing=1")

resp, _ := client.Do(req)
```

make a request with a json body:

```go
body, _err_ := json.Marshal(map[string]string{
    "id": id,
})

req, _err_ := http.NewRequest(http.MethodDelete, "https://api.xsshunter.com/api/delete_injection", bytes.NewBuffer(body))
req.Header.Add("X-CSRF-Token", csrf)
req.Header.Add("Cookie", cookie)

_, err = client.Do(req)
```

sending a file in a multipart form:

```golang
body := &bytes.Buffer{}
writer := multipart.NewWriter(body)
part, _ := writer.CreateFormFile("application/x-php", filename)
part.Write([]byte(content))
writer.Close()
req, _ := http.NewRequest(http.MethodPost, host+"/import", body)
req.Header.Add("Content-Type", writer.FormDataContentType())
req.Header.Add("Cookie", "PHPSESSID="+cookie)
resp, _ := client.Do(req)

if resp.StatusCode != 200 {
	body, _ := ioutil.ReadAll(resp.Body)
	html := string(body)
	log.Fatal(html)
}
```

reading response headers:

```go
sid := resp.Header["Set-Cookie"][0][4:36] // gets a sid value from the response header value
```

reading the response body:

```go
body, _ := ioutil.ReadAll(resp.Body)
fmt.Println(string(body))
```
