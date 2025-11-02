#include <stdint.h>
#include "ez80f92.h"
#include <stdlib.h>
#include "uart.h"

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

/* Initialize all maskable interrupts to a default handler. Already done during startup. */
extern "C" void _init_default_vectors(void);

enum IRQn {
    VECTOR_FLASH = 0x08,
    VECTOR_PRT_0 = 0x0A,
    VECTOR_PRT_1 = 0x0C,
    VECTOR_PRT_2 = 0x0E,
    VECTOR_PRT_3 = 0x10,
    VECTOR_PRT_4 = 0x12,
    VECTOR_PRT_5 = 0x14,
    VECTOR_RTC   = 0x16,
    VECTOR_UART0 = 0x18,
    VECTOR_UART1 = 0x1A,
    VECTOR_I2C   = 0x1C,
    VECTOR_SPI   = 0x1E,
    VECTOR_PB0   = 0x30,
    VECTOR_PB1   = 0x32,
    VECTOR_PB2   = 0x34,
    VECTOR_PB3   = 0x36,
    VECTOR_PB4   = 0x38,
    VECTOR_PB5   = 0x3A,
    VECTOR_PB6   = 0x3C,
    VECTOR_PB7   = 0x3E,
    VECTOR_PC0   = 0x40,
    VECTOR_PC1   = 0x42,
    VECTOR_PC2   = 0x44,
    VECTOR_PC3   = 0x46,
    VECTOR_PC4   = 0x48,
    VECTOR_PC5   = 0x4A,
    VECTOR_PC6   = 0x4C,
    VECTOR_PC7   = 0x4E,
    VECTOR_PD0   = 0x50,
    VECTOR_PD1   = 0x52,
    VECTOR_PD2   = 0x54,
    VECTOR_PD3   = 0x56,
    VECTOR_PD4   = 0x58,
    VECTOR_PD5   = 0x5A,
    VECTOR_PD6   = 0x5C,
    VECTOR_PD7   = 0x5E
};

/**
 * Installs a handler function for a certain interrupt.
 * @param vector The vector number to nset
 * @param handler The handler function to installer 
 * @return The vector that was installed previously
 */
extern "C" void * _set_vector(unsigned int vector, void(*handler)(void));

__attribute__((interrupt)) void UART0_Handler() {
    mytest = 456;
}

int main() {
    IO(PC_DDR) = 0x00; // make all Port C pins OUTPUT
    // some initial delay
    for(int j = 0; j < 50; j++) for(int i = 0; i < 65534; i++) { __asm(""); }

    uart0_init();

    _set_vector(VECTOR_UART0, UART0_Handler);

    while(1) {
        uart0_puts("Blinky and malloc\r\n");
        // in each iteration, try allocate a new 32K chunk
        void* p = malloc(32 * 1024);
        void* p2 = malloc(32 * 1024);
        uart0_puts("Malloced: 0x");
        uart0_putnum((int) p, 16);
        extern int __heaptop;
        uart0_puts(" Heap top: 0x");
        uart0_putnum((int) &__heaptop, 16);
        uart0_puts("\r\n");
        if(p == NULL) {
            testObject.set_val(10);
        }
        free(p); // free memory again
        free(p2);
        IO(PC_DR) = 0xFF; // turn all Port C pins on
        for(int j = 0; j < testObject.get_val(); j++) for(int i = 0; i < 65534; i++) { __asm(""); }
        IO(PC_DR) = 0x00; // turn all Port C pins off
        for(int j = 0; j < testObject.get_val(); j++) for(int i = 0; i < 65534; i++) { __asm(""); }
    }
    return 0;
}
