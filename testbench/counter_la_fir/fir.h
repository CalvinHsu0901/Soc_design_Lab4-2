#ifndef __FIR_H__
#define __FIR_H__
#include <stdint.h>
#include <stdbool.h>

#define N 64

int outputsignal[N];
// AP control
#define reg_fir_control (*(volatile uint32_t*)0x30000000)

// FIR input X, FIR output Y
#define reg_fir_x (*(volatile uint32_t*)0x30000080)
#define reg_fir_y (*(volatile uint32_t*)0x30000084)
#endif
