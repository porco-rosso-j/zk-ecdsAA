use dep::std;

// fn main(address : pub Field, salt: Field) {

//     let mut owner: [Field; 2] = [0; 2];
//     owner[0] = address;
//     owner[1] = salt;
//     let ownerHash = std::hash::pedersen(owner);
//     std::println(ownerHash);
// }

// fn main(address : pub Field) {
//     let mut owner: [Field; 1] = [0; 1];
//     owner[0] = address;
//     let ownerHash = std::hash::pedersen(owner);
//     std::println(ownerHash);
// }

fn main(addresses : pub [Field; 5]) {

      for i in 0..5 {
        let mut owner: [Field; 1] = [0; 1];
        owner[0] = addresses[i];
        let hashedAdd = std::hash::pedersen(owner);
        std::println(hashedAdd)
      }

      // owner/g1: 0x13ab2733d03b0c89ab8222acd18b002120fec289a54d5769536b3b758d8dc780
      // g2: 0x1c9fcea8cdb14e79710ec43e3f5a2c0b5c736586bd4a896c52033acab345577d
      // g3: 0x2cc5a2e55e9a482940665b3e3dc88a9e3b0cf90e6b4966f97c8b13fa686cfe5d
      // new owner: 0x1c02f61c7c5e6510aeee895347bd0ed9d1162d7038a33a364f65d511b2436d80
      // beneficiary: 0x108206375df5b41c4d706cd9d4715c38781d22ee9ff66a5cb887bbec403dea74
}

#[test]
fn test_main() {
    // main(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0);
    // 0x2840920c6b28172affa5533dbcec73f20e1a7d54cdb0c5d79b1297895c3c6d03
    // main(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    //0x13ab2733d03b0c89ab8222acd18b002120fec289a54d5769536b3b758d8dc780

    let addresses: [Field; 5] = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906,
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65
    ];

    // 0x13ab2733d03b0c89ab8222acd18b002120fec289a54d5769536b3b758d8dc780
    // 0x1c9fcea8cdb14e79710ec43e3f5a2c0b5c736586bd4a896c52033acab345577d
    // 

    main(addresses);


    // Uncomment to make test fail
    // main(1, 1);
}
