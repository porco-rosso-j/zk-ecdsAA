use dep::std;

fn main(address : pub Field, salt: Field) {

    let mut owner: [Field; 2] = [0; 2];
    owner[0] = address;
    owner[1] = salt;
    let ownerHash = std::hash::pedersen(owner);
    std::println(ownerHash);
}

// fn main(address : pub Field) {
//     let mut owner: [Field; 1] = [0; 1];
//     owner[0] = address;
//     let ownerHash = std::hash::pedersen(owner);
//     std::println(ownerHash);
// }

#[test]
fn test_main() {
    main(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0);
    0x2840920c6b28172affa5533dbcec73f20e1a7d54cdb0c5d79b1297895c3c6d03
    // main(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    //0x13ab2733d03b0c89ab8222acd18b002120fec289a54d5769536b3b758d8dc780

    // Uncomment to make test fail
    // main(1, 1);
}
