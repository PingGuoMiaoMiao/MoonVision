///|
#external
priv type Handler

///|
#borrow(path, mode)
extern "C" fn fopen_ffi(path : Bytes, mode : Bytes) -> Handler = "moonvision_demo_io_fopen_ffi"

///|
extern "C" fn is_null(ptr : Handler) -> Int = "moonvision_demo_io_is_null"

///|
#borrow(ptr)
extern "C" fn fread_ffi(
  ptr : Bytes,
  size : Int,
  nitems : Int,
  stream : Handler,
) -> Int = "moonvision_demo_io_fread_ffi"

///|
#borrow(ptr)
extern "C" fn fwrite_ffi(
  ptr : Bytes,
  size : Int,
  nitems : Int,
  stream : Handler,
) -> Int = "moonvision_demo_io_fwrite_ffi"

///|
extern "C" fn fseek_ffi(file : Handler, offset : Int, whence : Int) -> Int = "moonvision_demo_io_fseek_ffi"

///|
extern "C" fn ftell_ffi(file : Handler) -> Int = "moonvision_demo_io_ftell_ffi"

///|
extern "C" fn fflush_ffi(stream : Handler) -> Int = "moonvision_demo_io_fflush_ffi"

///|
extern "C" fn fclose_ffi(file : Handler) -> Int = "moonvision_demo_io_fclose_ffi"

///|
extern "C" fn get_error_message_ffi() -> Bytes = "moonvision_demo_io_get_error_message"

fn get_error_message() -> String {
  utf8_bytes_to_mbt_string(get_error_message_ffi())
}

fn read_bytes_from_file_internal(path : String) -> Bytes raise IOError {
  let file = fopen_ffi(mbt_string_to_utf8_bytes(path, true), b"rb\x00")
  guard is_null(file) == 0 else { raise IOError(get_error_message()) }
  guard fseek_ffi(file, 0, 2) == 0 else { raise IOError(get_error_message()) }
  let size = ftell_ffi(file)
  guard size != -1 else { raise IOError(get_error_message()) }
  guard fseek_ffi(file, 0, 0) == 0 else { raise IOError(get_error_message()) }
  let bytes = Bytes::make(size, 0)
  let bytes_read = fread_ffi(bytes, 1, size, file)
  guard bytes_read == size else { raise IOError(get_error_message()) }
  guard fclose_ffi(file) == 0 else { raise IOError(get_error_message()) }
  bytes
}

fn write_bytes_to_file_internal(
  path : String,
  content : Bytes,
) -> Unit raise IOError {
  let file = fopen_ffi(mbt_string_to_utf8_bytes(path, true), b"wb\x00")
  guard is_null(file) == 0 else { raise IOError(get_error_message()) }
  let bytes_written = fwrite_ffi(content, 1, content.length(), file)
  guard bytes_written == content.length() else {
    raise IOError(get_error_message())
  }
  guard fflush_ffi(file) == 0 else { raise IOError(get_error_message()) }
  guard fclose_ffi(file) == 0 else { raise IOError(get_error_message()) }
}

fn write_string_to_file_internal(
  path : String,
  content : String,
) -> Unit raise IOError {
  write_bytes_to_file_internal(path, mbt_string_to_utf8_bytes(content, false))
}

fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
  let res : Array[Char] = []
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c < 0x80 {
      res.push(Int::unsafe_to_char(c))
      i = i + 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.push(Int::unsafe_to_char(c))
      i = i + 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.push(Int::unsafe_to_char(c))
      i = i + 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c = c - 0x10000
      res.push(Int::unsafe_to_char((c >> 10) + 0xD800))
      res.push(Int::unsafe_to_char((c & 0x3FF) + 0xDC00))
      i = i + 4
    }
  }
  String::from_array(res)
}
