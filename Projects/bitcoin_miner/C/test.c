#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <error.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <endian.h>

#define IN_CNT 4
#define RES_CNT 2
#define BYTES_NR 76
#define TIME_OFFSET 40

#define HASH_ENDOFF 32
#define NONCE_ENDOFF 36

static uint8_t tx_buf[BYTES_NR] = {
	0x09, 0xA0, 0xD1, 0x91, 0x92, 0xEF, 0x77, 0xC3, 0x04, 0xFE, 0x44,
	0x78, 0x88, 0xF9, 0xEF, 0x50, 0x69, 0xD6, 0x48, 0x46, 0x5A, 0x19,
	0x14, 0x6F, 0xB7, 0x70, 0x61, 0x97, 0x14, 0xD0, 0x89, 0x04, 0x45,
	0xF4, 0x99, 0x2E, 0x74, 0x74, 0x90, 0x54, 0x74, 0x7B, 0x1B, 0x18,

	0x00, 0x00, 0x00, 0x0F, 0x00, 0x00, 0x00, 0x00, 0xA2, 0x94, 0x08,
	0x84, 0xE0, 0xC3, 0xBC, 0x96, 0x51, 0x0C, 0xAD, 0x11, 0x91, 0x2A,
	0x52, 0x7E, 0x9D, 0x15, 0xDF, 0x42, 0xF0, 0xE1, 0xD6, 0x72};

static uint8_t rx_buf[76];
static uint32_t time, be_time;

int main(int argc, char **argv)
{
	int fd;
	int i;
	ssize_t ret, len;

	fd = open("/dev/miner0.0", O_RDWR);
	if (fd == -1) {
		perror("Could not open dev");
		exit(EXIT_FAILURE);
	}

	sleep(1);

while(1) {
	while (1) {
		ret = write(fd, tx_buf, BYTES_NR);
		if (ret == -1) {
			if (errno == EINTR)
				continue;
			perror ("write");
			exit(EXIT_FAILURE);
		}
		if (ret == BYTES_NR)
			break;
	}

	while (1) {
		ret = read(fd, rx_buf, BYTES_NR);
		if (ret == -1) {
			if (errno == EINTR)
				continue;
			if (errno == EAGAIN) {
				printf("Couldn't find any hashes. Continuing...\n");
				goto next;
			}
			perror ("read");
			exit(EXIT_FAILURE);
		}
		if (ret == BYTES_NR)
			break;
	}

	printf("Hash: 0x");
	for (i=0; i < HASH_ENDOFF; ++i)
		printf("%02X", rx_buf[i]);
	printf("\n");

	printf("Nonce: 0x");
	for (; i < NONCE_ENDOFF; ++i)
		printf("%02X", rx_buf[i]);
	printf("\n\n");

next:
	++time;
	be_time = htobe32(time);
	memcpy(tx_buf+TIME_OFFSET, &be_time, 4);
}
	close(fd);
	return EXIT_SUCCESS;
}
