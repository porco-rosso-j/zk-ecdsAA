
use dep::std;

fn to_first_32(array_x: [u8; 64]) -> [u8; 32] {
      let mut combined: [u8; 32] = [0; 32];

      for i in 0..32 {
          combined[i] = array_x[i];
      }

      combined
}

fn to_second_32(array_x: [u8; 64]) -> [u8; 32] {
      let mut combined: [u8; 32] = [0; 32];
      let mut j = 0;
      for i in 0..32 {
        j = i + 32;
        //std::println(j);
        combined[i] = array_x[j];
      }
      combined
}

fn to_first_64(array_x: [u8; 128]) -> [u8; 64] {
      let mut combined: [u8; 64] = [0; 64];

      for i in 0..64 {
          combined[i] = array_x[i];
      }

      combined
}

fn to_second_64(array_x: [u8; 128]) -> [u8; 64] {
      let mut combined: [u8; 64] = [0; 64];
      let mut j = 0;
      for i in 0..64 {
        j = i + 64;
        combined[i] = array_x[j];
      }
      combined
}

#[test] 
fn test_to_first_32() {
    let ret = to_first_32(TEST_ARRAY_64);

    // 141
    let tenth = ret[10];
    std::println(tenth);
}

#[test] 
fn test_to_second_32() {
    let ret = to_second_32(TEST_ARRAY_64);

    // 38
    let tenth = ret[10];
    std::println(tenth);
}

#[test] 
fn test_to_first_64() {
    let ret = to_first_64(TEST_ARRAY_128);

    let zero = ret[0]; // 118
    std::println(zero);
    let thirty3 = ret[32]; // 50
    std::println(thirty3);
}


#[test] 
fn test_to_second_64() {
    let ret = to_second_64(TEST_ARRAY_128);

    let zero = ret[0]; // 50
    std::println(zero);
    let thirty3 = ret[32]; // 118
    std::println(thirty3);
}



global TEST_ARRAY_64: [u8;64]
 = [
    118, 190, 21, 249, 139, 28, 162, 171, 252, 167, 234, 29, 188, 180, 82, 241, 91, 191, 193, 206, 15, 102, 35, 4, 79, 76, 69, 27, 27, 191, 31, 128,
    50, 49, 102, 29, 255, 107, 87, 223, 119, 141, 38, 132, 19, 105, 246, 167, 216, 172, 148, 34, 60, 43, 97, 141, 11, 223, 40, 120, 196, 61, 42, 79
   ];

global TEST_ARRAY_128: [u8;128]
 = [
    118, 190, 21, 249, 139, 28, 162, 171, 252, 167, 234, 29, 188, 180, 82, 241, 91, 191, 193, 206, 15, 102, 35, 4, 79, 76, 69, 27, 27, 191, 31, 128,
    50, 49, 102, 29, 255, 107, 87, 223, 119, 141, 38, 132, 19, 105, 246, 167, 216, 172, 148, 34, 60, 43, 97, 141, 11, 223, 40, 120, 196, 61, 42, 79,
    50, 49, 102, 29, 255, 107, 87, 223, 119, 141, 38, 132, 19, 105, 246, 167, 216, 172, 148, 34, 60, 43, 97, 141, 11, 223, 40, 120, 196, 61, 42, 79,
    118, 190, 21, 249, 139, 28, 162, 171, 252, 167, 234, 29, 188, 180, 82, 241, 91, 191, 193, 206, 15, 102, 35, 4, 79, 76, 69, 27, 27, 191, 31, 128,
   ];