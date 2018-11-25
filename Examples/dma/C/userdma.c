#include "userdma.h"

void dma_set(unsigned int* dma_virtual_address, int offset, unsigned int value) {
  dma_virtual_address[offset>>2] = value;
}

unsigned int dma_get(unsigned int* dma_virtual_address, int offset) {
  return dma_virtual_address[offset>>2];
}


unsigned int dma_get_mm2s_status_reg(struct axi_dma *ptr) {
  return ptr->axi_regs[MM2S_STATUS_REGISTER>>2];
}

unsigned int dma_get_s2mm_status_reg(struct axi_dma *ptr) {
  return ptr->axi_regs[S2MM_STATUS_REGISTER>>2];
}

unsigned int dma_get_mm2s_control_reg(struct axi_dma *ptr) {
  return ptr->axi_regs[MM2S_CONTROL_REGISTER>>2];
}

unsigned int dma_get_s2mm_control_reg(struct axi_dma *ptr) {
  return ptr->axi_regs[S2MM_CONTROL_REGISTER>>2];
}


void dma_set_mm2s_status_reg(struct axi_dma *ptr, unsigned int value) {
  ptr->axi_regs[MM2S_STATUS_REGISTER>>2] = value;
}

void dma_set_s2mm_status_reg(struct axi_dma *ptr, unsigned int value) {
  ptr->axi_regs[S2MM_STATUS_REGISTER>>2] = value;
}

void dma_set_mm2s_control_reg(struct axi_dma *ptr, unsigned int value) {
  ptr->axi_regs[MM2S_CONTROL_REGISTER>>2] = value;
}

void dma_set_s2mm_control_reg(struct axi_dma *ptr, unsigned int value) {
  ptr->axi_regs[S2MM_CONTROL_REGISTER>>2] = value;
}


void dma_reset(struct axi_dma *ptr) {
  printf("Resetting DMA\n");
  
  dma_set_mm2s_status_reg(ptr, 1 << 12);
  dma_set_s2mm_status_reg(ptr, 1 << 12);

  // resetting DMA
  dma_set_s2mm_control_reg(ptr, 4);
  dma_set_mm2s_control_reg(ptr, 4);

  // halting DMA
  dma_set_s2mm_control_reg(ptr, 0);
  dma_set_mm2s_control_reg(ptr, 0);

  // Clear destination block
  memset(ptr->dest_mapping, 0, 4 * 8);
}

void dma_s2mm_status(struct axi_dma *axi_ptr) {
  unsigned int status = dma_get_s2mm_status_reg(axi_ptr);
  
  printf("Stream to memory-mapped status (0x%08x@0x%02x):", status, S2MM_STATUS_REGISTER);
  if (status & 0x00000001) printf(" halted"); else printf(" running");
  if (status & 0x00000002) printf(" idle");
  if (status & 0x00000008) printf(" SGIncld");
  if (status & 0x00000010) printf(" DMAIntErr");
  if (status & 0x00000020) printf(" DMASlvErr");
  if (status & 0x00000040) printf(" DMADecErr");
  if (status & 0x00000100) printf(" SGIntErr");
  if (status & 0x00000200) printf(" SGSlvErr");
  if (status & 0x00000400) printf(" SGDecErr");
  if (status & 0x00001000) printf(" IOC_Irq");
  if (status & 0x00002000) printf(" Dly_Irq");
  if (status & 0x00004000) printf(" Err_Irq");
  printf("\n");
}

void dma_mm2s_status(struct axi_dma *axi_ptr) {
  unsigned int status = dma_get_mm2s_status_reg(axi_ptr);

  printf("Memory-mapped to stream status (0x%08x@0x%02x):", status, MM2S_STATUS_REGISTER);
  if (status & 0x00000001) printf(" halted"); else printf(" running");
  if (status & 0x00000002) printf(" idle");
  if (status & 0x00000008) printf(" SGIncld");
  if (status & 0x00000010) printf(" DMAIntErr");
  if (status & 0x00000020) printf(" DMASlvErr");
  if (status & 0x00000040) printf(" DMADecErr");
  if (status & 0x00000100) printf(" SGIntErr");
  if (status & 0x00000200) printf(" SGSlvErr");
  if (status & 0x00000400) printf(" SGDecErr");
  if (status & 0x00001000) printf(" IOC_Irq");
  if (status & 0x00002000) printf(" Dly_Irq");
  if (status & 0x00004000) printf(" Err_Irq");
  printf("\n");
}

void dma_mm2s_sync(struct axi_dma *axi_ptr) {
  unsigned int mm2s_status =  dma_get_mm2s_status_reg(axi_ptr);

  printf("Waiting for MM2S synchronization...\n");
  
  while(!(mm2s_status & 1<<12) || !(mm2s_status & 1<<1) ){
    dma_s2mm_status(axi_ptr);
    dma_mm2s_status(axi_ptr);

    mm2s_status =  dma_get_mm2s_status_reg(axi_ptr);
  }
}

void dma_s2mm_sync(struct axi_dma *axi_ptr) {
  unsigned int s2mm_status = dma_get_s2mm_status_reg(axi_ptr);

  printf("Waiting for S2MM sychronization...\n");
  while(!(s2mm_status & 1<<12) || !(s2mm_status & 1<<1)){
    dma_s2mm_status(axi_ptr);
    dma_mm2s_status(axi_ptr);

    s2mm_status = dma_get_s2mm_status_reg(axi_ptr);
  }
}

void memdump(void* virtual_address, int byte_count)
{
  char *p = virtual_address;
  int offset;
  for (offset = 0; offset < byte_count; offset++) {
    printf("%02x", p[offset]);
    if (offset % 4 == 3) { printf(" "); }
  }
  printf("\n");
}

struct axi_dma *dma_init(unsigned int src_addr, unsigned int dest_addr)
{
  int fd;
  unsigned int *virtual_addr;
  unsigned int *virtual_src_addr;
  unsigned int *virtual_dest_addr;

  struct axi_dma *axi_ptr;
  
  fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd < 0) {
    perror("Error opening /dev/mem");
    exit(1);
  }

  axi_ptr = malloc(sizeof(*axi_ptr));
  if (axi_ptr == NULL) {
    perror("Could not allocate struct axi_dma");
    exit(1);
  }
  
  virtual_addr = mmap(NULL, 65535, PROT_READ | PROT_WRITE, MAP_SHARED, fd, AXI_BASE); // Memory map AXI Lite register block
  virtual_src_addr  = mmap(NULL, 65535, PROT_READ | PROT_WRITE, MAP_SHARED, fd, src_addr); // Memory map source address
  virtual_dest_addr = mmap(NULL, 65535, PROT_READ | PROT_WRITE, MAP_SHARED, fd, dest_addr); // Memory map destination address

  axi_ptr->axi_regs = virtual_addr;
  axi_ptr->src_mapping = virtual_src_addr;
  axi_ptr->dest_mapping = virtual_dest_addr;
  axi_ptr->src = src_addr;
  axi_ptr->dest = dest_addr;
  
  return axi_ptr;
}

void dma_send_rcv(struct axi_dma *axi_ptr, unsigned int s2mm_size, unsigned int mm2s_size)
{
  unsigned int *virtual_address = axi_ptr->axi_regs;
  
  printf("Writing destination address\n");
  dma_set(virtual_address, S2MM_DESTINATION_ADDRESS, axi_ptr->dest); // Write destination address
  dma_s2mm_status(axi_ptr);

  printf("Writing source address...\n");
  dma_set(virtual_address, MM2S_START_ADDRESS, axi_ptr->src); // Write source address
  dma_mm2s_status(axi_ptr);

  printf("Starting S2MM channel with all interrupts masked...\n");
  dma_set(virtual_address, S2MM_CONTROL_REGISTER, 0xF001);
  dma_s2mm_status(axi_ptr);

  printf("Starting MM2S channel with all interrupts masked...\n");
  dma_set(virtual_address, MM2S_CONTROL_REGISTER, 0xF001);
  dma_mm2s_status(axi_ptr);

  printf("Writing S2MM transfer length...\n");
  dma_set(virtual_address, S2MM_LENGTH, s2mm_size); //4 * 8
  dma_s2mm_status(axi_ptr);

  printf("Writing MM2S transfer length...\n");
  dma_set(virtual_address, MM2S_LENGTH, mm2s_size); // 4* 20
  dma_mm2s_status(axi_ptr);

  dma_mm2s_sync(axi_ptr);
  dma_s2mm_sync(axi_ptr);
}

void dma_free(struct axi_dma *axi_ptr)
{
  munmap(axi_ptr->axi_regs, 65535);
  munmap(axi_ptr->src_mapping, 65535);
  munmap(axi_ptr->dest_mapping, 65535);

  free(axi_ptr);
}
