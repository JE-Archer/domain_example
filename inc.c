#include <stdint.h>
#include <microkit.h>

volatile int *shared_counter;

void print_unsigned_int(unsigned int n) {
    if (n / 10) {
        print_unsigned_int(n / 10);
    }
    microkit_dbg_putc((n % 10) + '0');
}

void
notified(microkit_channel ch)
{
}

void
init(void)
{
    unsigned int id = microkit_name[3] - '0';
    while (1) {
        if ((*shared_counter % 3) == id) {
            microkit_dbg_puts(microkit_name);
            microkit_dbg_puts(": *shared_counter = ");
            print_unsigned_int(*shared_counter);
            microkit_dbg_puts(", incrementing to ");
            (*shared_counter)++;
            print_unsigned_int(*shared_counter);
            microkit_dbg_putc('\n');
        }
    }
}
