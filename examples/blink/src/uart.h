#ifndef __UART_H_
#define __UART_H_

#ifdef __cplusplus
extern "C" {
#endif

void uart0_init(void);
void uart0_putc(char c);
void uart0_puts(const char *s);
void uart0_putnum(int val, int radix);

#ifdef __cplusplus
}
#endif

#endif