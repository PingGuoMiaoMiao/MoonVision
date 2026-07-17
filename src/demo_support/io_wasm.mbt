///|
fn unsupported_file_io(path : String) -> IOError {
  IOError(
    "demo_support file I/O is only available on native and js targets: " + path,
  )
}

///|
fn read_bytes_from_file_internal(path : String) -> Bytes raise IOError {
  raise unsupported_file_io(path)
}

///|
fn write_bytes_to_file_internal(
  path : String,
  content : Bytes,
) -> Unit raise IOError {
  ignore(content)
  raise unsupported_file_io(path)
}

///|
fn write_string_to_file_internal(
  path : String,
  content : String,
) -> Unit raise IOError {
  ignore(content)
  raise unsupported_file_io(path)
}
