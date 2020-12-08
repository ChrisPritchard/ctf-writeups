package main

import (
	"bufio"
	"log"
	"net"
	"strings"

	"golang.org/x/net/proxy"
)

func main() {
	dialer, err := proxy.SOCKS5("tcp", "127.0.0.1:8888", nil, proxy.Direct)
	if err != nil {
		log.Fatalln(err)
	}
	println("connected to proxy")

	conn, err := dialer.Dial("tcp", "172.15.21.133:5555")
	//conn, err := net.Dial("tcp", "172.15.21.133:5555")
	if err != nil {
		log.Fatalln(err)
	}
	println("connected to service")

	reader := bufio.NewReader(conn)

	quit := false
	p := make([]byte, 2048)
	pos := 2

	for !quit {
		n, err := reader.Read(p)

		if err != nil {
			log.Fatalln(err)
		}

		read := string(p[:n])
		println(read)

		lines := strings.Split(read, "\n")
		if len(lines) > 1 {
			dangerLine := lines[len(lines)-3]
                        nextLine := lines[len(lines)-2]
			
			if dangerLine[pos] == '0' {
				if pos > 1 && dangerLine[pos-1] != '0' {
					conn.Write([]byte{0x1b, 0x5b, 0x44}) // left
					pos--
				} else if pos < len(nextLine)-1 && dangerLine[pos+1] != '0' {
					conn.Write([]byte{0x1b, 0x5b, 0x43}) // right
					pos++
				}
			}
		}
	}
}

func evade(pos int, nextLine string, conn net.Conn) int {
	if pos > 1 {
		conn.Write([]byte{0x1b, 0x5b, 0x44}) // left
		pos--
	} else if pos < len(nextLine)-1 {
		conn.Write([]byte{0x1b, 0x5b, 0x43}) // right
		pos++
	}
	return pos
}
