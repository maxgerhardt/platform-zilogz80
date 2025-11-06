#ifndef __VECTORS_H_
#define __VECTORS_H_

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize all maskable interrupts to a default handler. Already done during startup. */
void _init_default_vectors(void);

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
 void * _set_vector(unsigned int vector, void(*handler)(void));

#ifdef __cplusplus
}
#endif

#endif /* __VECTORS_H_ */