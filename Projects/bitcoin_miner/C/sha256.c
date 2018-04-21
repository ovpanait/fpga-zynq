#include <stdio.h>
#include <stdint.h>
#include <assert.h>

typedef uint32_t u32;
typedef uint8_t u8;

/* Sha256 constants
 * https://csrc.nist.gov/csrc/media/publications/fips/180/4/archive/2012-03-06/documents/fips180-4.pdf
 * page 11
 */
static const uint32_t K[] = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
			     0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
			     0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
			     0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
			     0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
			     0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
			     0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
			     0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};

/*
 * Sha256 functions 
 * https://csrc.nist.gov/csrc/media/publications/fips/180/4/archive/2012-03-06/documents/fips180-4.pdf
 * page 10
 */
static inline u32 rot_l32(u32 val, u8 shift)
{
	/* Debug info */
	assert(shift <= 32);
	
	return (val << shift) | (val >> (32 - shift));
}

static inline u32 rot_r32(u32 val, u8 shift)
{
	/* Debug */
	assert(shift <= 32);

	return (val >> shift) | (val << (32 - shift));
}

static inline u32 ch(u32 x, u32 y, u32 z)
{
	return (x & y) ^ (~x & z);
}

static inline u32 maj(u32 x, u32 y, u32 z)
{
	return (x & y) ^ (x & z) ^ (y & z);
}

static inline u32 ep0(u32 x)
{
	return rot_r32(x, 2) ^ rot_r32(x, 13) ^ rot_r32(x, 22);
}

static inline u32 ep1(u32 x)
{
	return rot_r32(x, 6) ^ rot_r32(x, 11) ^ rot_r32(x, 25);
}

static inline u32 sig0(u32 x)
{
	return rot_r32(x, 7) ^ rot_r32(x, 18) ^ (x >> 3);
}

static inline u32 sig1(u32 x)
{
	return rot_r32(x, 17) ^ rot_r32(x, 19) ^ (x >> 10);
}

int main(int argc, char **argv)
{
	/* Test rotates */
	assert(rot_l32(0xFFFFFF00, 8) == 0xFFFF00FF);
	assert(rot_r32(0xFFFFFF00, 8) == 0x00FFFFFF);
	assert(rot_l32(0xFFFFFF00, 0) == 0xFFFFFF00);
	assert(rot_l32(0x12FFFF00, 32) == 0x12FFFF00);
	printf("Success\n");

}
