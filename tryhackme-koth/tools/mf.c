#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/fs.h>

int main(int argc, char **argv)
{
    FILE *fp;

    if ((fp = fopen(argv[1], "r")) == NULL) {
        perror("fopen(3) error");
        exit(EXIT_FAILURE);
    }

    int val = atoi(argv[2]); // 16 adds the immutable flag, 0 removes it
    if (ioctl(fileno(fp), FS_IOC_SETFLAGS, &val) < 0)
        perror("ioctl(2) error");

    fclose(fp);

    return 0;
}
