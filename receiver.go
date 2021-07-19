package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

func main() {
	port := "8888"
	if len(os.Args) == 2 {
		port = os.Args[1]
	}
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		err := r.ParseMultipartForm(32 << 20)
		if err != nil {
			return
		}
		file, header, err := r.FormFile("file")
		if err != nil {
			return
		}
		defer file.Close()

		fmt.Printf("received file with name '%s':\n\n", header.Filename)

		var buf bytes.Buffer
		io.Copy(&buf, file)
		contents := buf.String()
		fmt.Println(contents)
	})

	fmt.Println("listing on port " + port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
	//log.Fatal(http.ListenAndServeTLS(":"+port, "receiver.crt", "receiver.key", nil))
}
