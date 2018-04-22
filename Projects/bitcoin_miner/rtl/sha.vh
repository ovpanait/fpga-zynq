`ifndef sha_vh
 `define sha_vh

 `define W_SIZE 32
 `define W_MAX (`W_SIZE - 1)

// sha256 functions
 `define rot_r(val, shift) ({val[shift - 1: 0], val[`W_MAX : shift]})
 `define rot_l(val, shift) ({val[`W_MAX - shift: 0], val[`W_MAX : `W_SIZE - shift]})
 `define ch(x,y,z) ((x & y) ^ (~x & z))
 `define maj(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
 `define ep0(x) (`rot_r(x, 2) ^ `rot_r(x, 13) ^ `rot_r(x, 22))
 `define ep1(x) (`rot_r(x, 6) ^ `rot_r(x, 11) ^ `rot_r(x, 25))
 `define sig0(x) (`rot_r(x, 7) ^ `rot_r(x, 18) ^ (x >> 3))
 `define sig1(x) (`rot_r(x, 17) ^ `rot_r(x, 19) ^ (x >> 10))

`endif
