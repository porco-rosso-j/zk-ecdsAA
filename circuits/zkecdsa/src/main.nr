use dep::std;
mod array;
mod ecrecover;

fn main(
    hashedAddr: pub Field,
    pub_key: [u8; 64], 
    signature: [u8; 64], 
    message_hash: pub [u8; 32],
) {

    let pubkey_x = array::to_first_32(pub_key);
    let pubkey_y = array::to_second_32(pub_key);

    let recovered_addr = ecrecover::ecrecover(
        pubkey_x,
        pubkey_y,
        signature,
        message_hash
    );

    std::println(recovered_addr);

    let mut addr: [Field; 1] = [0; 1];
    addr[0] = recovered_addr;

    let computed_root = std::hash::pedersen(addr);
    std::println(computed_root);
    std::println(hashedAddr);

    assert(computed_root[0] == hashedAddr);
}

#[test]
fn test_main() {

// is this userOp hash or not...?
let message_hash = [244, 76, 64, 128, 236, 209, 131, 235, 199, 196, 208, 190, 254, 189, 11, 114, 21, 72, 62, 62, 228, 167, 27, 214, 176, 254, 219, 48, 156, 187, 175, 109];

let pub_key = [
  131,  24,  83,  91,  84,  16, 93,  74, 122, 174,  96,
  192, 143, 196,  95, 150, 135, 24,  27,  79, 223, 198,
   37, 189,  26, 117,  63, 167, 57, 127, 237, 117,  53,
   71, 241,  28, 168, 105, 102, 70, 242, 243, 172, 176,
  142,  49,   1, 106, 250, 194, 62,  99,  12,  93,  17,
  245, 159,  97, 254, 245, 123, 13,  42, 165
];

let hashedAddr = 0x2840920c6b28172affa5533dbcec73f20e1a7d54cdb0c5d79b1297895c3c6d03;
let signature = [
  247, 102, 238, 229, 166, 185, 153, 196, 118,  89, 130,
  230,  55,  15,  25, 236,  56,  94, 220,  16,  31, 116,
  241,  51,  79,   0, 193, 235, 139,  77,  35,  69,  53,
  132, 190,   0, 222,  52,  35, 222,  81,  28, 183, 137,
  135, 149,  66, 130, 181, 149,  17, 115, 207, 145, 248,
  198,  41, 190, 204, 133,  55,  38,  48, 144
];

main(hashedAddr, pub_key, signature, message_hash);
//    std::println(ret);
//    assert(ret == true);
}