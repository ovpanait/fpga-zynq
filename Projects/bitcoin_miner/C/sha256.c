#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include <endian.h>
#include <stdlib.h>
#include "sha256.h"

/* Sha256 standard specifications taken from:
 * https://csrc.nist.gov/csrc/media/publications/fips/180/4/archive/2012-03-06/documents/fips180-4.pdf
 */

/* Sha256 constants
 * page 11
 */
static const u32 K[] = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	};

static const u32 H0[] = {
	0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
	0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
	};

/*
 * Sha256 functions
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

/* Helper functions */
static u8 to_hex(char c)
{
	if (isdigit(c))
		return (c - '0');

	if (c >= 'A' && c <= 'F')
		return (c - 'A' + 10);

	return 0xFF;
}
/*
 * Sha256 preprocessing
 * page 13
 */
/* The bitcoin message is always 640 bits */
void parse_pad(struct sha256_data *co, char *i_msg)
{
	size_t len = strnlen(i_msg, NIMB_MAX + 1); /* Number of input symbols */
	uint64_t len_bits;
	size_t len_k, i, j;
	u8 *ptr;

	printf("len: %lu\n", len);

	if (len > NIMB_MAX) {
		printf("ERROR: Truncating input\n");
		exit(EXIT_FAILURE);
	}

	/* We use memcpy to copy the number of input bits, so store it
	 * directly in big endian format.
	 */
	len_bits = htobe64(len * 4);

	/* Compute k */
	len_k = 512 - (len_bits % 448) - 1;
	ptr = co->msg;

	/* Always assume even number of inputs. Zero out everything first.*/
	memset(ptr, 0, BYTES_MAX);

	for (i = 0; i < len; i += 2)
		*ptr++ = (to_hex(i_msg[i]) << 4) | (to_hex(i_msg[i + 1]));

	/* Add one 1 bit, k zeros and copy message length */
	*ptr++ = 0x01 << 7;
	memcpy((co->msg + BYTES_MAX)- 8, &len_bits, 8);

	#ifdef DEBUG
	printf("final message: ");
	for (i = 0; i < BYTES_MAX; ++i) {
		printf("%02X", co->msg[i]);
		if (i == (BYTES_MAX / 2))
			printf("\n");
	}
	printf("\n");
	#endif
}

void sha256_compute(struct sha256_data *co, char *i_msg)
{
	u32 a, b, c, d, e, f, g, h, T1, T2, H[8];
	size_t i, t;
	u32 W[64];
	u8 msg_index;

	/* Initialize. Parse and pad the input. */
	msg_index = 0;
	for (i = 0; i < 8; ++i)
		H[i] = H0[i];

	parse_pad(co, i_msg);


	for (i = 0; i < BLOCKS_NO; ++i) {
		a = H[0];
		b = H[1];
		c = H[2];
		d = H[3];
		e = H[4];
		f = H[5];
		g = H[6];
		h = H[7];


		// Fully unrolled
		/* Initialize message scheduler */
		for (t = 0; t < 64; ++t) {
			if (t < 16)
				W[t] = htobe32(*((u32 *)(co->msg + msg_index + t * 4)));
			else
				W[t] = sig1(W[t - 2]) + W[t - 7] + sig0(W[t - 15]) + W[t - 16];

			#ifdef DEBUG
			//printf("sig1(W[t - 2]): %08X\n", sig1(W[t - 2]));
			//printf("W[t - 7]: %08X\n", W[t - 7]);
			//printf("sig0(W[t - 15]):%08X\n", sig0(W[t - 15]));
			//printf("W[t - 16]: %08X\n", W[t - 16]);
			printf("W[%u]: %08X\n", t + 1, W[t]);
			#endif
		}

		// Debug W
		#ifdef DEBUG
		printf("\n");
		printf("W:\n");
		for (t = 32; t > 0; --t)
			printf("%08X", W[t-1]);
		printf("\n");
		#endif

		// Fully unrolled
		/* 64 rounds */
		for (t = 0; t < 64; ++t) {
			#ifdef DEBUG
			printf("Hash[%u] - In\n", t);
			printf("%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n\n",
				a, b, c, d, e, f, g, h);
			#endif

			T1 = h + ep1(e) + ch(e,f,g) + K[t] + W[t];
			T2 = ep0(a) + maj(a,b,c);
			h = g;
			g = f;
			f = e;
			e = d + T1;
			d = c;
			c = b;
			b = a;
			a = T1 + T2;

			#ifdef DEBUG
			printf("Hash[%u] - Out\n", t);
			printf("%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n%08X \n\n",
				a, b, c, d, e, f, g, h);
			#endif
		}

		// 1 stage
		H[0] += a;
		H[1] += b;
		H[2] += c;
		H[3] += d;
		H[4] += e;
		H[5] += f;
		H[6] += g;
		H[7] += h;

		/* Go to block M2 */
		msg_index += 64;
	}

	#ifdef DEBUG
	printf("sha256: ");
	for (i = 0; i < 8; ++i)
		printf("%08X", H[i]);
	printf("\n");
	#endif

}


int main(int argc, char **argv)
{

	#ifdef DEBUG
	struct sha256_data test_str = {0};
	/* Test rotates */
	assert(rot_l32(0xFFFFFF00, 8) == 0xFFFF00FF);
	assert(rot_r32(0xFFFFFF00, 8) == 0x00FFFFFF);
	assert(rot_l32(0xFFFFFF00, 0) == 0xFFFFFF00);
	assert(rot_l32(0x12FFFF00, 32) == 0x12FFFF00);
	printf("Success\n");

	printf("K - 32:\n");
	for (int i = 31; i >= 0; --i)
		printf("%08X", K[i]);
	printf("\n");

	#define DEBUG_TESTVAL "02000000671D0E2FF45DD1E927A51219D1CA1065C93B0C4E8840290A00000000000000002CD900FC3513260DF5BD2EABFD456CD2B3D2BACE30CC078215A907C045F4992E74749054747B1B1843F740C0"
	printf("sig1: %08X\n", sig1(0x8207CC30));
	sha256_compute(&test_str, DEBUG_TESTVAL);
	#endif
}
