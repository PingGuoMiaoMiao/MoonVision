#ifdef __cplusplus
extern "C" {
#endif

#include "moonbit.h"

typedef unsigned long long size_t;
typedef struct _iobuf FILE;

#ifndef NULL
#define NULL ((void *)0)
#endif

extern FILE *fopen(const char *filename, const char *mode);
extern size_t fread(void *buffer, size_t size, size_t count, FILE *stream);
extern size_t fwrite(const void *buffer, size_t size, size_t count, FILE *stream);
extern int fseek(FILE *stream, long offset, int origin);
extern long ftell(FILE *stream);
extern int fflush(FILE *stream);
extern int fclose(FILE *stream);
extern void *memcpy(void *dest, const void *src, size_t count);
extern size_t strlen(const char *str);

MOONBIT_FFI_EXPORT FILE *moonvision_demo_io_fopen_ffi(moonbit_bytes_t path,
                                                      moonbit_bytes_t mode) {
  return fopen((const char *)path, (const char *)mode);
}

MOONBIT_FFI_EXPORT int moonvision_demo_io_is_null(void *ptr) {
  return ptr == NULL;
}

MOONBIT_FFI_EXPORT size_t moonvision_demo_io_fread_ffi(moonbit_bytes_t ptr,
                                                       int size, int nitems,
                                                       FILE *stream) {
  return fread(ptr, size, nitems, stream);
}

MOONBIT_FFI_EXPORT size_t moonvision_demo_io_fwrite_ffi(moonbit_bytes_t ptr,
                                                        int size,
                                                        int nitems,
                                                        FILE *stream) {
  return fwrite(ptr, size, nitems, stream);
}

MOONBIT_FFI_EXPORT int moonvision_demo_io_fseek_ffi(FILE *stream, long offset,
                                                    int whence) {
  return fseek(stream, offset, whence);
}

MOONBIT_FFI_EXPORT long moonvision_demo_io_ftell_ffi(FILE *stream) {
  return ftell(stream);
}

MOONBIT_FFI_EXPORT int moonvision_demo_io_fflush_ffi(FILE *file) {
  return fflush(file);
}

MOONBIT_FFI_EXPORT int moonvision_demo_io_fclose_ffi(FILE *stream) {
  return fclose(stream);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t moonvision_demo_io_get_error_message(void) {
  const char *err_str = "I/O error";
  size_t len = strlen(err_str);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, err_str, len);
  return bytes;
}

#ifdef __cplusplus
}
#endif
