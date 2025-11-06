#include <stdint.h>
#include "ez80f92.h"
#include "vectors.h"
#include "prt0.h"

//==============================================================
// Clock configuration
//==============================================================

#define SYSCLK_FREQ_HZ     18432000UL   // 18.432 MHz system clock
#define TIMER_FREQ_HZ      1000UL       // 1 kHz (1 ms period)

//==============================================================
// Bit masks for TMRx_CTL (from product spec)
//==============================================================

enum {
    TMR_CTL_PRT_EN     = (1 << 0),  // Enable timer
    TMR_CTL_RST_EN     = (1 << 1),  // Auto-reload enable
    TMR_CTL_CLKDIV_4   = (0 << 2),  // input clock dividers
    TMR_CTL_CLKDIV_16  = (1 << 2),
    TMR_CTL_CLKDIV_64  = (2 << 2),
    TMR_CTL_CLKDIV_256 = (3 << 2),
    TMR_CTL_MODE_SP    = (0 << 4),  // single pass mode
    TMR_CTL_MODE_CONT  = (1 << 4),  // Continuous mode
    TMR_CTL_IRQ_EN     = (1 << 6),  // Interrupt enable
    TMR_CTL_PRT_IRQ    = (1 << 7)   // timer has reached end of count? (readonly)
};

//==============================================================
// Globals
//==============================================================

static volatile unsigned int ms = 0;  // millisecond counter
extern "C" void PRT0_Handler(void);

//==============================================================
// Helper: compute reload value
//==============================================================
//
// Timer period = (Reload * Divider) / SYSCLK
//
// For 1 ms period → Reload = SYSCLK * 1e-3 / Divider
//
// We'll pick Divider = 64 for good granularity
//

static inline uint16_t compute_reload(void)
{
    const uint32_t divider = 64;
    uint32_t reload = (SYSCLK_FREQ_HZ / divider) / TIMER_FREQ_HZ;
    return (uint16_t)reload;
}

//==============================================================
// Timer initialization
//==============================================================

void PRT0_Init(void)
{
    // 1. Disable timer during setup
    IO(TMR0_CTL) = 0x00;

    // 2. Hook ISR to vector
    _set_vector(VECTOR_PRT_0, PRT0_Handler);
    __asm("ei");

    // 3. Select system clock as input source for TMR0 (bits [1:0] = 00)
    IO(TMR_ISS) &= ~0x03;

    // 4. Compute and load reload value
    uint16_t reload = compute_reload();
    IO(TMR0_RR_L) = (uint8_t)(reload & 0xFF);
    IO(TMR0_RR_H) = (uint8_t)(reload >> 8);

    // 5. Configure control register:
    //    - Enable reload
    //    - Continuous mode
    //    - /64 clock divider
    //    - Interrupt enable
    //    - Start timer
    IO(TMR0_CTL) = TMR_CTL_RST_EN |
                   //TMR_CTL_MODE_SP  |
                   TMR_CTL_MODE_CONT |
                   //TMR_CTL_CLKDIV_256 |
                   TMR_CTL_CLKDIV_64 |
                   TMR_CTL_IRQ_EN |
                   TMR_CTL_PRT_EN;
}

unsigned int get_ms() {
    return ms;
}

uint16_t get_timer_cnt() {
    uint8_t low = IO(TMR0_DR_L);
    uint8_t high = IO(TMR0_DR_H);
    return (uint16_t)((high << 16u) | low);
}

//==============================================================
// Interrupt Service Routine for PRT0
//==============================================================

__attribute__((interrupt))
void PRT0_Handler(void)
{
    // Reading TMR0_CTL clears the interrupt flag
    // (this IO read will not be optimized away (good)!)
    IO(TMR0_CTL);

    // Increment the millisecond counter
    ms++;
    __asm("ei");
}
