///|
pub(all) suberror IOError {
  IOError(String)
} derive(Eq, Show)

///|
pub fn write_bytes_to_file(
  path : String,
  content : Bytes,
) -> Unit raise IOError {
  write_bytes_to_file_internal(path, content)
}

///|
pub fn read_bytes_from_file(path : String) -> Bytes raise IOError {
  read_bytes_from_file_internal(path)
}

///|
pub fn write_string_to_file(
  path : String,
  content : String,
) -> Unit raise IOError {
  write_string_to_file_internal(path, content)
}
