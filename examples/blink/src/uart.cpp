#include <stdint.h>
#include <ez80f92.h>
#include "uart.h"

/* nonstandard but often used function.. */
extern "C" int itoa(int value, char *sp, int radix);

/* =========================================================
 * UART0 configuration constants for eZ80F92 @ 18.432 MHz
 * ---------------------------------------------------------
 * Baud rate generator formula (datasheet):
 *
 *     Baud = SYSCLK / (16 × BRG_divisor)
 *
 * Therefore:
 *     BRG_divisor = SYSCLK / (16 × Baud)
 * =========================================================
 */
#define SYSCLK_HZ              18432000UL
#define UART0_BAUD             115200UL

/* BRG divisor computation (integer division) */
#define UART0_BRG_DIVISOR      (SYSCLK_HZ / (16UL * UART0_BAUD))   /* = 10 */

/* Split divisor into high/low bytes for BRG registers */
#define UART0_BAUD_DIV_LOW     (uint8_t)(UART0_BRG_DIVISOR & 0xFF) /* 0x0A */
#define UART0_BAUD_DIV_HIGH    (uint8_t)(UART0_BRG_DIVISOR >> 8)   /* 0x00 */

/* =========================================================
 * UART0 line control (LCTL) bit definitions
 * ---------------------------------------------------------
 * Bit7 DLAB : Divisor Latch Access Bit (1 = set baud regs)
 * Bit6–5    : reserved (0)
 * Bit4 EPS  : Even Parity Select
 * Bit3 PEN  : Parity Enable
 * Bit2–0    : Word length
 *
 *   8 data bits, no parity, 1 stop bit => 0b0000_0011 = 0x03
 * =========================================================
 */
#define LCTL_DLAB              0x80    /* Enable divisor latch access */
#define LCTL_8N1               0x03    /* 8 data bits, no parity, 1 stop */

/* =========================================================
 * UART0 modem control (MCTL)
 * ---------------------------------------------------------
 * Normal mode, no loopback, RTS/CTS disabled.
 * =========================================================
 */
#define MCTL_NORMAL             0x00

/* =========================================================
 * UART0 line status (LSR) bits
 * ---------------------------------------------------------
 * Bit5 THRE : Transmit Holding Register Empty
 * Bit6 TEMT : Transmitter Empty (optional use)
 * =========================================================
 */
#define LSR_THRE                0x20
#define LSR_TEMT                0x40

/* =========================================================
 * UART0 initialization and transmit routines
 * =========================================================
 */
void uart0_init(void) {
    /* Map PD0/PD1 to UART0 TXD/RXD (ALT2 = 1, ALT1 = 0, DDR = 1) */
    IO(PD_ALT1) = 0x00;
    IO(PD_ALT2) = (1 << 0) | (1 << 1); /* PD0 and PD1 */
    IO(PD_DDR)  = (1 << 0) | (1 << 1); /* PD0 and PD1 */

    /* Disable UART interrupts (polling mode) */
    IO(UART0_IER) = 0x00;

    /* Enable divisor latch access to set baud rate */
    IO(UART0_LCTL) = LCTL_DLAB;

    /* Set baud rate divisor (18.432 MHz / (16×115200) = 10) */
    IO(UART0_BRG_L) = UART0_BAUD_DIV_LOW;   /* 0x0A */
    IO(UART0_BRG_H) = UART0_BAUD_DIV_HIGH;  /* 0x00 */

    /* Restore normal access, 8 data, no parity, 1 stop */
    IO(UART0_LCTL) = LCTL_8N1;

    /* Normal modem control mode */
    IO(UART0_MCTL) = MCTL_NORMAL;
}

[[gnu::always_inline]] inline void uart0_putc(char c) {
    /* Wait until transmit holding register is empty */
    while (!(IO(UART0_LSR) & LSR_THRE))
        ;
    IO(UART0_THR) = (uint8_t)c;
}

/* =========================================================
 * Transmit a zero-terminated string (polling)
 * =========================================================
 */
void uart0_puts(const char *s) {
    while (*s)
        uart0_putc(*s++);
}

void uart0_putnum(int val, int radix) {
    char buf[26] = {};  // -1113
    itoa(val, buf, radix);
    uart0_puts(buf);
}