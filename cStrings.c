#include <stdio.h>
#include <string.h>

int main() {
    // A simple C string with a newline
    char str[] = "Hello World!";

    // Print the string as is
    printf("Original string:\n%s\n", str);

    // Show the length of the string (excluding the null terminator)
    printf("Length of the string (excluding null terminator): %zu\n", strlen(str));

    // Display each character of the string including the null terminator
    printf("Characters in the string:\n");
    for (int i = 0; i <= strlen(str); i++) {  // Loop over including the null terminator
        printf("Character at index %d: '%c' (ASCII: %d)\n", i, str[i], (int)str[i]);
    }

    // Demonstrate that '\n' is ASCII 10
    printf("\nASCII value of '\\n': %d\n", '\n');

    return 0;
}
