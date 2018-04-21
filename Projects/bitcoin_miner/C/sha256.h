#ifndef SHA256_H
#define SHA256_H

#define BITS_MAX 1024
#define NIMB_MAX (BITS_MAX / 4)
#define BYTES_MAX (BITS_MAX / 8)

#define BLOCK_SIZE 512
#define BLOCKS_NO 2

typedef uint32_t u32;
typedef uint8_t u8;

struct sha256_data {
	u8 msg[128];
};

#endif
