package main

import (
	"bufio"
	"io"
	"log"
	"strings"

	"golang.org/x/net/proxy"
)

func main() {
	dialer, err := proxy.SOCKS5("tcp", "127.0.0.1:9080", nil, proxy.Direct)
	if err != nil {
		log.Fatalln(err)
	}
	println("connected to proxy")

	conn, err := dialer.Dial("tcp", "172.17.23.149:20001")
	if err != nil {
		log.Fatalln(err)
	}
	println("connected to service")

	// easy_mode(conn)
	hard_mode(conn)
}

func easy_mode(conn io.ReadWriter) {

	conn.Write([]byte(`{"StartGame":{"game_mode":"Easy"}}` + "\n"))
	println("started game")

	reader := bufio.NewReader(conn)
	p := make([]byte, 2048)

	for {
		n, err := reader.Read(p)

		if err != nil {
			log.Fatalln(err)
		}

		read := string(p[:n])
		print(read)

		if strings.HasPrefix(read, `{"TargetCreated"`) {
			start := strings.Index(read, "x")
			conn.Write([]byte(`{"ClientClick":{"` + read[start:] + "\n"))
		}

		conn.Write([]byte(`{"ClientHeartBeat":{}}` + "\n"))
	}
}

func hard_mode(conn io.ReadWriter) {

	conn.Write([]byte{0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x0c, 0x00, 0x02, 0x00, 0x01,
		0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0c,
		0x00, 0x02, 0x4e, 0x84, 0x00, 0x00, 0x00, 0x03})
	println("started game")

	reader := bufio.NewReader(conn)
	p := make([]byte, 2048)

	for {
		n, err := reader.Read(p)

		if err != nil {
			log.Fatalln(err)
		}

		read := p[:n]
		print(string(read))

		if read[3] == 0x38 && read[13] == 0x02 {
			conn.Write([]byte{
				0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x0c, 0x00, 0x02, 0x00, 0x01,
				0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x0c,
				0x00, 0x02, 0x4e, 0xe8, 0x00, 0x00, read[42], read[43],
				0x00, 0x00, 0x00, 0x0c, 0x00, 0x02, 0x4e, 0xe9,
				0x00, 0x00, read[54], read[55]})
		}

		conn.Write([]byte{0x00, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x0c, 0x00, 0x02, 0x00, 0x01,
			0x00, 0x00, 0x00, 0x01})
	}
}
