///|
test "gray image construction and pixel access" {
  let img = try! gray_from_array(2, 2, [b'\x01', b'\x02', b'\x03', b'\x04'])
  inspect(img.width(), content="2")
  inspect(img.height(), content="2")
  inspect(img.get(1, 0), content="b'\\x02'")
  inspect(img.get(0, 1), content="b'\\x03'")
}

///|
test "gray image rejects bad buffer length" {
  let err = try? gray_from_array(2, 2, [b'\x01'])
  inspect(
    err,
    content="Err(InvalidBufferLength(4, 1))",
  )
}

///|
test "rgb image stores and reads triples" {
  let img = try! rgb(2, 1, fill=rgb_pixel(b'\x00', b'\x00', b'\x00'))
  try! img.set(1, 0, rgb_pixel(b'\x10', b'\x20', b'\x30'))
  let pixel = try! img.get(1, 0)
  inspect(pixel.r(), content="b'\\x10'")
  inspect(pixel.g(), content="b'\\x20'")
  inspect(pixel.b(), content="b'\\x30'")
}

fn fixture_png_chunk(chunk_type : Bytes, data : Bytes) -> Bytes {
  let len = data.length()
  let len_bytes = FixedArray::make(4, b'\x00')
  len_bytes[0] = ((len.reinterpret_as_uint() >> 24).reinterpret_as_int() & 0xFF).to_byte()
  len_bytes[1] = ((len.reinterpret_as_uint() >> 16).reinterpret_as_int() & 0xFF).to_byte()
  len_bytes[2] = ((len.reinterpret_as_uint() >> 8).reinterpret_as_int() & 0xFF).to_byte()
  len_bytes[3] = (len & 0xFF).to_byte()
  let crc_input = FixedArray::make(4 + len, b'\x00')
  crc_input.blit_from_bytes(0, chunk_type, 0, 4)
  crc_input.blit_from_bytes(4, data, 0, len)
  let crc = @zlib.crc32_fixed(crc_input)
  let crc_bytes = FixedArray::make(4, b'\x00')
  crc_bytes[0] = (crc >> 24).land(0xFFU).to_byte()
  crc_bytes[1] = (crc >> 16).land(0xFFU).to_byte()
  crc_bytes[2] = (crc >> 8).land(0xFFU).to_byte()
  crc_bytes[3] = crc.land(0xFFU).to_byte()
  let total = 12 + len
  let buf = FixedArray::make(total, b'\x00')
  buf.blit_from_bytes(0, Bytes::from_array(len_bytes), 0, 4)
  buf.blit_from_bytes(4, chunk_type, 0, 4)
  buf.blit_from_bytes(8, data, 0, len)
  buf.blit_from_bytes(8 + len, Bytes::from_array(crc_bytes), 0, 4)
  Bytes::from_array(buf)
}

fn concat_fixture_bytes(parts : Array[Bytes]) -> Bytes {
  let total = parts.fold(init=0, fn(acc, part) { acc + part.length() })
  let buf = FixedArray::make(total, b'\x00')
  let mut offset = 0
  for part in parts {
    buf.blit_from_bytes(offset, part, 0, part.length())
    offset = offset + part.length()
  }
  Bytes::from_array(buf)
}

fn fixture_png_2x2() -> Bytes {
  let ihdr = b"\x00\x00\x00\x02\x00\x00\x00\x02\x08\x06\x00\x00\x00"
  let raw = b"\x00\xFF\x00\x00\xFF\x00\xFF\x00\xFF\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF"
  let compressed = @zlib.zlib_compress(raw)
  concat_fixture_bytes([
    b"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A",
    fixture_png_chunk(b"\x49\x48\x44\x52", ihdr),
    fixture_png_chunk(b"\x49\x44\x41\x54", compressed),
    fixture_png_chunk(b"\x49\x45\x4E\x44", b""),
  ])
}

///|
test "png decoding adapts RGBA data to rgb image" {
  let img = try! rgb_from_png_bytes(fixture_png_2x2())
  inspect(img.width(), content="2")
  inspect(img.height(), content="2")
  inspect(img.to_array(), content="[b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\xFF', b'\\xFF']")
}
