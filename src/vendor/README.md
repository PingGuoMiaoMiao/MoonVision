# Vendored Code

This directory contains adapted third-party MoonBit code used only for local PNG encode/decode support.

| Local path | Upstream project | Upstream repository | License |
| --- | --- | --- | --- |
| `imagecodec/` | `mizchi/image` | <https://github.com/mizchi/image-mbt> | Apache-2.0 |
| `zlib/` | `mizchi/zlib` | <https://github.com/mizchi/zlib.mbt> | Apache-2.0 |

The full Apache-2.0 license text is retained in `../../LICENSES/Apache-2.0.txt`.

MoonVision adapts these sources to its own package layout and narrows the exposed API to the PNG bridge used by `GrayImage`, `RgbImage`, and `export`.
