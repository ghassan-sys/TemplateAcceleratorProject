#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "mmio.h"

// Define MMIO register addresses mapping
#define MMIO_BASE_ADDRESS          0x50000  // Replace with the actual base address of the MMIO module
#define MMIO_STATUS MMIO_BASE_ADDRESS
#define MMIO_FUNCT_REG             (MMIO_BASE_ADDRESS + 0x04)
#define MMIO_DATA_OUT_REG          (MMIO_BASE_ADDRESS + 0x08)

#define CFG_REG_WIDTH 16
#define NUM_OF_CFG_REGS 1024
#define DATA_WIDTH 8
#define ADDR_WIDTH 16

// define commands encodings
#define COMPUTE 2
#define CONFIG 1

int main() {
	int result, ref;
	unsigned long cycle1, cycle2, total_cycles;
	cycle1=0;
	cycle2=0;
	result = 0;
	ref = 6;
	printf("start of main program!\n\n");
	asm volatile("rdcycle %0" : "=r" (cycle1));

	// wait for the peripheral to be ready
	while((reg_read8(MMIO_STATUS) & 0x2) == 0);
	for(int i = 0; i < NUM_OF_CFG_REGS; i++){

		// need to perform shift operations
		if(CFG_REG_WIDTH < ADDR_WIDTH){
		volatile	int addr_to_shift;
			addr_to_shift = 0;
			for(int j = 0; j < i % (ADDR_WIDTH / CFG_REG_WIDTH); j++){
				addr_to_shift = addr_to_shift << (DATA_WIDTH);
			}
			
		}
		switch(CFG_REG_WIDTH){
			case 8:
				// write to the peripheral
				reg_write8(MMIO_FUNCT_REG, CONFIG);
				// wait for peripheral to be ready
				while((reg_read8(MMIO_STATUS) & 0x1) == 0);
				result = reg_read32(MMIO_DATA_OUT_REG);

			break;
			case 16:
				// write to the peripheral
				reg_write16(MMIO_FUNCT_REG, CONFIG);
				// wait for peripheral to be ready
				while((reg_read8(MMIO_STATUS) & 0x1) == 0);
				result = reg_read32(MMIO_DATA_OUT_REG);

			break;
			case 32:
				// write to the peripheral
				reg_write32(MMIO_FUNCT_REG, CONFIG);
				// wait for peripheral to be ready
				while((reg_read8(MMIO_STATUS) & 0x1) == 0);
				result = reg_read32(MMIO_DATA_OUT_REG);
			break;
			case 64:
			break;
			case 128:
			break;
			default: 
				printf("ERROR! Got an unexpected Register Width %d", CFG_REG_WIDTH);

			return 1;
			break;
	
		}

		// wait for the peripheral to be ready
		while((reg_read8(MMIO_STATUS) & 0x2) == 0);
	}

	// wait for peripheral to be ready
  	//while ((reg_read8(MMIO_STATUS) & 0x2) == 0) ;
	
	// write to the peripheral
	switch(CFG_REG_WIDTH){

		case 8:
			reg_write8(MMIO_FUNCT_REG, COMPUTE);
		break;
		case 16:
			reg_write16(MMIO_FUNCT_REG, COMPUTE);
		break;
		case 32:
			reg_write32(MMIO_FUNCT_REG, COMPUTE);
		break;
		case 64:
		break;
		default:
			printf("ERROR! Got an unexpected Register Width %d", CFG_REG_WIDTH);
		break;
	}


	// wait for the peripheral to complete
	while((reg_read8(MMIO_STATUS) & 0x1) == 0);
	// data out reg is always of width 32 bits.
	result = reg_read32(MMIO_DATA_OUT_REG);

	// finish the cycle count
	asm volatile("rdcycle %0" : "=r" (cycle2));
	total_cycles = cycle2 - cycle1;
	printf("cycle1=%lu cycle2=%lu total_time=%lu\n", cycle1, cycle2, total_cycles);

    if (result != ref) {
        printf("Hardware result %d does not match reference value %d\n", result, ref);
        return 1;
    }

    printf("\n\nHardware result is correct for MMIO Accelerator! execution took %lu cycles\n", total_cycles);
    return 0;
}
