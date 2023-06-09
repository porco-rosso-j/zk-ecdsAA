use dep::std;

// credit: https://github.com/colinnielsen/ecrecover-noir/tree/main/src

    fn ecrecover(
      pub_key_x: [u8; 32],
      pub_key_y: [u8; 32],
      signature: [u8; 64], // clip v value
      hashed_message: [u8; 32]
    ) -> pub Field {
      assert(verify_sig(pub_key_x, pub_key_y, signature, hashed_message) == true);
      let addr = to_eth_address(pub_key_x, pub_key_y);
      addr 
    }

    fn verify_sig(pub_key_x: [u8; 32], pub_key_y: [u8; 32], signature: [u8; 64], hashed_message: [u8; 32]) -> bool {
        let isValid = std::ecdsa_secp256k1::verify_signature(pub_key_x, pub_key_y, signature, hashed_message);
        isValid == 1
    }

    fn to_eth_address(pub_key_x: [u8; 32], pub_key_y: [u8; 32]) -> Field {
        let pub_key = unify_pub_x_pub_y(pub_key_x, pub_key_y);
        let hashed_pub_key = std::hash::keccak256(pub_key);

        u8_32_to_u160(hashed_pub_key)
    }

    fn unify_pub_x_pub_y(array_x: [u8; 32], array_y: [u8; 32]) -> [u8; 64] {
      let mut combined: [u8; 64] = [0; 64];

      for i in 0..32 {
          combined[i] = array_x[i];
      }
      for i in 0..32 {
        combined[i + 32] = array_y[i];
      }
      combined
    }

    fn u8_32_to_u160(array: [u8; 32]) -> Field {
      let mut addr: Field = 0;

      for i in 0..20 {
        // only take the last 20 bytes of the hash
        addr = (addr * 256) + (array[i + 12] as Field);
      }

      addr
    }
