#ifndef __PRT0_H_
#define __PRT0_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void PRT0_Init(void);
unsigned int get_ms();
uint16_t get_timer_cnt();

#ifdef __cplusplus
}
#endif

#endif