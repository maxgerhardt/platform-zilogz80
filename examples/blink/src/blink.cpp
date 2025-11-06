#include <stdint.h>
#include "ez80f92.h"
#include <stdlib.h>
#include "uart.h"
#include "prt0.h"

volatile int mytest = 10;

class MyTestClass {
    public:
    MyTestClass(uint16_t x) : testvar(x) { };
    uint16_t get_val() {
        return this->testvar;
    }
    void set_val(uint16_t newval) {
        this->testvar = newval;
    }

    private:
    uint16_t testvar;
};

MyTestClass testObject(3);

extern char _2nd_jump_table;
extern unsigned short _nvectors;

void print_vector_table() {
    // each entry in the vector table is 4 byte (0xC3 JMP opcode and 3 byte address)
    const uint32_t* pTbl = (uint32_t*) &_2nd_jump_table;
    uart0_puts("Vectable at 0x");
    uart0_putnum((int) pTbl, 16);
    uart0_puts("\r\n");
    for(unsigned short i = 0; i < _nvectors; i++) {
        uint8_t* bytePtr = (uint8_t*)(&pTbl[i]);
        uart0_puts("Vec "); uart0_putnum(i, 10); 
        uart0_puts(" (@ 0x"); uart0_putnum((int) bytePtr, 16); 
        uart0_puts("): ");
        for(uint8_t j = 0; j < 4; j++) {
            uart0_puts("0x");
            uart0_putnum(bytePtr[j], 16); 
            uart0_puts(" ");
        }
        uart0_puts("\r\n");
    }
}

int main() {
    IO(PC_DDR) = 0x00; // make all Port C pins OUTPUT
    // some initial delay
    for(int j = 0; j < 50; j++) for(int i = 0; i < 65534; i++) { __asm(""); }

    uart0_init();
    print_vector_table();
    uart0_puts("Millis: "); uart0_putnum((int) get_ms(), 10); uart0_puts("\r\n");
    PRT0_Init();
    print_vector_table();

    while(1) {
        uart0_puts("Millis: "); uart0_putnum((int) get_ms(), 10);
        uart0_puts(" Tim: " ); uart0_putnum((int) get_timer_cnt(), 10);
        uart0_puts(" Ctrl: "); uart0_putnum( (int) IO(TMR0_CTL), 16);
        uart0_puts("\r\n");
        IO(PC_DR) = 0xFF; // turn all Port C pins on
        for(int j = 0; j < testObject.get_val(); j++) for(int i = 0; i < 65534; i++) { __asm(""); }
        IO(PC_DR) = 0x00; // turn all Port C pins off
        for(int j = 0; j < testObject.get_val(); j++) for(int i = 0; i < 65534; i++) { __asm(""); }
    }
    return 0;
}
