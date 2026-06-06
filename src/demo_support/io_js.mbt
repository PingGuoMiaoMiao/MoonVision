///|
extern "js" fn write_file_ffi(path : String, content : Bytes) -> Int =
  #| function(path, content) {
  #|   var fs = require('fs');
  #|   try {
  #|     fs.writeFileSync(path, Buffer.from(content));
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.moonvisionDemoIoError = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn get_error_message_ffi() -> String =
  #| function() {
  #|   return globalThis.moonvisionDemoIoError || '';
  #| }

fn write_bytes_to_file_internal(
  path : String,
  content : Bytes,
) -> Unit raise IOError {
  if write_file_ffi(path, content) == -1 {
    raise IOError(get_error_message_ffi())
  }
}

fn write_string_to_file_internal(
  path : String,
  content : String,
) -> Unit raise IOError {
  write_bytes_to_file_internal(path, mbt_string_to_utf8_bytes(content, false))
}
