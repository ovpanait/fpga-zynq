`ifndef sha_vh
 `define sha_vh

 `define WORD_S 32 // 32-bit word size

/* Bitcoin header components sizes  */
 `define VERSION_S (`WORD_S)
 `define TIME_S (`WORD_S)
 `define NBITS_S (`WORD_S)

 `define DELAY 16

 `define BLK_SIZE 512

 `define MSG_S 512
 `define MSG_BLKCNT (`MSG_S / `WORD_S)

 `define W_BLKCNT 16
 `define WARR_S `W_BLKCNT * `WORD_S

 `define H_SIZE `WORD_S * 8

 `define K_SIZE `WORD_S * 64

// sha256 functions
 `define rot_r(val, shift) ({val[shift - 1: 0], val[`WORD_S-1 : shift]})
 `define rot_l(val, shift) ({val[`WORD_S-1 - shift: 0], val[`WORD_S-1 : `WORD_S - shift]})
 `define ch(x,y,z) ((x & y) ^ (~x & z))
 `define maj(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
 `define ep0(x) (`rot_r(x, 2) ^ `rot_r(x, 13) ^ `rot_r(x, 22))
 `define ep1(x) (`rot_r(x, 6) ^ `rot_r(x, 11) ^ `rot_r(x, 25))
 `define sig0(x) (`rot_r(x, 7) ^ `rot_r(x, 18) ^ (x >> 3))
 `define sig1(x) (`rot_r(x, 17) ^ `rot_r(x, 19) ^ (x >> 10))

// array manipulations
 `define VEC_I(i) (i)*`WORD_S +:`WORD_S

`endif
