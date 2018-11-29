#include <stdio.h>
#include <stdint.h>

#include "userdma.h"

#define FIFO_IN_LEN 4 * 20
#define FIFO_OUT_LEN 4 * 8

void load_inputs(struct axi_dma *dma_transfer)
{
  uint32_t M []= {
    0x02000000, // BLK_VERSION
    0x671D0E2F, 0xF45DD1E9, 0x27A51219, 0xD1CA1065, 0xC93B0C4E, 0x8840290A, 0x00000000, 0x00000000, // prev_blk_header_hash
    0x2CD900FC, 0x3513260D, 0xF5BD2EAB, 0xFD456CD2, 0xB3D2BACE, 0x30CC0782, 0x15A907C0, 0x45F4992E, // merkle_root_hash
    0x74749054, // blk_time
    0x747B1B18, // blk_nbits
    0x43F740C0 // blk_nonce
  };
    
  for (int i = 0; i < 20; ++i)
    dma_transfer->src_mapping[i] = M[i];

  printf("Source memory block:      ");
  memdump(dma_transfer->src_mapping, FIFO_IN_LEN);

  printf("Destination memory block: ");
  memdump(dma_transfer->dest_mapping, FIFO_OUT_LEN);

}

int main (int argc, char **argv)
{
  struct axi_dma *dma_transfer;
  
  dma_transfer = dma_init(0x0e000000, 0x0f000000);
  
  dma_reset(dma_transfer);

  load_inputs(dma_transfer);

  dma_send_rcv(dma_transfer, FIFO_OUT_LEN, FIFO_IN_LEN);

  printf("Destination memory block: ");
  memdump(dma_transfer->dest_mapping, FIFO_OUT_LEN);

  dma_free(dma_transfer);
  
  return 0;
}
