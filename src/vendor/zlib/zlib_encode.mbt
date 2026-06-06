///| Adapted from mizchi/zlib (Apache-2.0)

fn write_u32_be(out : FixedArray[Byte], offset : Int, v : Int) -> Unit {
  out[offset] = ((v >> 24) & 0xff).to_byte()
  out[offset + 1] = ((v >> 16) & 0xff).to_byte()
  out[offset + 2] = ((v >> 8) & 0xff).to_byte()
  out[offset + 3] = (v & 0xff).to_byte()
}

///|
pub fn zlib_compress(data : Bytes) -> Bytes {
  let deflated = deflate_compress_best(data)
  let total_len = 2 + deflated.length() + 4
  let result : FixedArray[Byte] = FixedArray::make(total_len, b'\x00')
  result[0] = b'\x78'
  result[1] = b'\x01'
  for i = 0; i < deflated.length(); i = i + 1 {
    result[2 + i] = deflated[i]
  }
  let checksum = adler32(data)
  write_u32_be(result, 2 + deflated.length(), checksum)
  Bytes::from_array(result)
}
