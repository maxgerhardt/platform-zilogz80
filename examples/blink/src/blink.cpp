#include <stdint.h>
#include "ez80f92.h"

int main() {
    IO(PC_DDR) = 0x00; // make all Port C pins OUTPUT
    while(1) {
        IO(PC_DR) = 0xFF; // turn all Port C pins on
        for(int j = 0; j < 10; j++) for(int i = 0; i < 65534; i++) { __asm(""); }
        IO(PC_DR) = 0x00; // turn all Port C pins off
        for(int j = 0; j < 10; j++) for(int i = 0; i < 65534; i++) { __asm(""); }
    }
    return 0;
}
