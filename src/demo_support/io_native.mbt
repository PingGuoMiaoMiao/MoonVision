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
extern "C" fn fwrite_ffi(
  ptr : Bytes,
  size : Int,
  nitems : Int,
  stream : Handler,
) -> Int = "moonvision_demo_io_fwrite_ffi"

///|
extern "C" fn fflush_ffi(stream : Handler) -> Int = "moonvision_demo_io_fflush_ffi"

///|
extern "C" fn fclose_ffi(file : Handler) -> Int = "moonvision_demo_io_fclose_ffi"

///|
extern "C" fn get_error_message_ffi() -> Bytes = "moonvision_demo_io_get_error_message"

fn get_error_message() -> String {
  utf8_bytes_to_mbt_string(get_error_message_ffi())
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
