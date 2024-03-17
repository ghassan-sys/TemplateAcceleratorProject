#include <stdio.h>
#include <stdint.h>
#include "include/encoding.h"
#include "rocc-software/src/xcustom.h"
#include <time.h>


#ifdef __linux
#include <sys/mman.h>
#endif

#ifndef __aligned
#define __aligned(x) __attribute__ ((aligned (x)))
#endif


#define DATA_WIDTH 8
#define NUM_OF_CFG_REGS 2
#define ADDR_WIDTH 8
#define CFG_REG_WIDTH 32
#define COMPUTE 2
#define CONFIG 1


int main() {

	unsigned long start_time, end_time, configure_time, compute_time;
	

#ifdef __linux
  // Ensure all pages are resident to avoid accelerator page faults

 	if (mlockall(MCL_CURRENT | MCL_FUTURE)) {
    perror("mlockall");
    return 1;
  }
#endif

  do {
    printf("Start template accelerator  <-->  Rocket test.\n");
    // Setup some test data
    int rd, rs1, rs2, i, trash, num_addr_in_reg;
    unsigned long long cycle1, cycle2, cycle3, cycle4;  
    num_addr_in_reg = 1 ;
    
    printf("start of test\n");
    configure_time = 0;
    printf("start writing to config registers, num of config registers is %d\n\n", NUM_OF_CFG_REGS);
    asm volatile ("rdcycle %0" : "=r" (cycle1));
    for(i=0; i < NUM_OF_CFG_REGS; i++){
	    if (ADDR_WIDTH >  CFG_REG_WIDTH){
		volatile int addr_to_reg, addr;
		addr_to_reg = 0;
		num_addr_in_reg = ADDR_WIDTH / CFG_REG_WIDTH;
		for(addr = 0; addr < (i %  num_addr_in_reg); addr++){
			addr_to_reg = addr_to_reg >> ADDR_WIDTH;
		}
	    	ROCC_INSTRUCTION(2, trash, i, rs2, CONFIG);
		asm volatile ("rdcycle %0" : "=r" (cycle4));

	    }

	    else{
	    	ROCC_INSTRUCTION(2, trash, i, rs2, CONFIG);
		asm volatile("rdcycle %0" : "=r" (cycle4));
	    }
    }

    // so that the pipeline doesn't get stuck.
    asm volatile ("rdcycle %0" : "=r" (cycle3));

    // custom command
    ROCC_INSTRUCTION(2, rd, rs1, rs2, COMPUTE);

    // finish
    asm volatile ("rdcycle %0" : "=r" (cycle2));
    compute_time = cycle2 - cycle1;

    printf("CUSTOM command SUCECESS!!\n");
    printf("got data in rd = %d\n", rd);
    printf("time took to write from CPU to accelerator is %lu cycles \n", compute_time);

    // Check result
    int res = 6;
	    
    printf("expected = %d vs output = %d\n", res, rd);
    if(rd != res) {
      printf("Failed: Outputs don't match!\n");
      printf("RoCC Accelerator execution took %lu cycles\n", configure_time + compute_time);
      return 1;
    }
  } while(0);

  printf("\n\nRoCC Accelerator SUCCESS! execution took %lu cycles\n", configure_time + compute_time);
  return 0;
}
