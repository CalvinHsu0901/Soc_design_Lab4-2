#include "fir.h"

// void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
// 	// initial your fir
	
	
// 	return;
// }

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){ 
	// initial first
	// initfir();
	reg_fir_control = 1; //set ap_start, bit[0] = 1

	for (int i=0; i<64; i++){
		while((reg_fir_control >> 4) & 1 != 1); // external signal x[n] ready, wait until bit[4] = 1
		reg_fir_x = i;
		while((reg_fir_control >> 5) & 1 != 1); // external signal y[n] ready, wait until bit[5] = 1
		outputsignal[i] = reg_fir_y;
	}
	while((reg_fir_control >> 1) & 1 != 1); // read ap_done, bit[1] = 1

	return &outputsignal[63];
}
		
