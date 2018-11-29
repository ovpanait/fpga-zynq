#ifndef ZYNQ_USER_DMA
#define ZYNQ_USER_DMA

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <sys/mman.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#define AXI_BASE 0x40400000
#define MM2S_CONTROL_REGISTER 0x00
#define MM2S_STATUS_REGISTER 0x04
#define MM2S_START_ADDRESS 0x18
#define MM2S_LENGTH 0x28

#define S2MM_CONTROL_REGISTER 0x30
#define S2MM_STATUS_REGISTER 0x34
#define S2MM_DESTINATION_ADDRESS 0x48
#define S2MM_LENGTH 0x58


struct axi_dma {
  unsigned int *axi_regs;
  
  unsigned int *src_mapping;
  unsigned int *dest_mapping;
  
  unsigned int src;
  unsigned int dest;
};

void dma_mm2s_sync(struct axi_dma *axi_ptr);
void dma_s2mm_sync(struct axi_dma *axi_ptr);

void dma_send_rcv(struct axi_dma *axi_ptr, unsigned int s2mm_size, unsigned int mm2s_size);
void dma_free(struct axi_dma *axi_ptr);
void dma_reset(struct axi_dma *ptr);

unsigned int dma_get(unsigned int* dma_virtual_address, int offset);
void dma_set(unsigned int* dma_virtual_address, int offset, unsigned int value);
struct axi_dma *dma_init(unsigned int src_addr, unsigned int dest_addr);

void memdump(void* virtual_address, int byte_count);

#endif
