#include <stdlib.h>
#include <stdio.h>

void shell_code()
{
    char command[] = {'/','b','i','n','/','s','h',0};
    system(command);
}

void end_shell_code() {}

int main() 
{
    int sizeOfShellCode = (int)end_shell_code - (int)shell_code;
    FILE *output_file = fopen("shellcode.bin", "w");
    fwrite(shell_code, sizeOfShellCode, 1, output_file);
    fclose(output_file);

    return 0;
}