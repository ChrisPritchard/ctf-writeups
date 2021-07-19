// for TLS, generate a cert with `openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out returner.crt -keyout returner.key`
package main

import (
        "fmt"
        "log"
        "net/http"
        "os"
)

func main() {
        port := "8888"
        if len(os.Args) == 3 {
                port = os.Args[2]
        }
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
                http.ServeFile(w, r, os.Args[1])
                fmt.Println("received request and returning file")
        })

        fmt.Println("listing on port " + port)
        // HTTP only: log.Fatal(http.ListenAndServe(":"+port, nil))
        log.Fatal(http.ListenAndServeTLS(":"+port, "returner.crt", "returner.key", nil))
}
