# Third-Party Notices

MoonVision is licensed under the MIT license. Some vendored codec and compression code is adapted from Apache-2.0 licensed upstream MoonBit projects.

## Vendored Sources

| Local path | Upstream project | Upstream repository | Upstream license | Notes |
| --- | --- | --- | --- | --- |
| `src/vendor/imagecodec/` | `mizchi/image` | <https://github.com/mizchi/image-mbt> | Apache-2.0 | Adapted PNG codec and image data primitives for MoonVision's `RgbImage`/PNG bridge. |
| `src/vendor/zlib/` | `mizchi/zlib` | <https://github.com/mizchi/zlib.mbt> | Apache-2.0 | Adapted zlib/deflate helpers used by local PNG encode/decode support. |

The upstream `mizchi/image-mbt` README identifies the package as `mizchi/image`, describes image codec primitives for MoonBit, and lists the license as Apache-2.0. The upstream `mizchi/zlib.mbt` README identifies the package as `mizchi/zlib` and lists the license as Apache-2.0.

MoonVision changes include package layout adaptation, API narrowing to the PNG functionality needed by MoonVision, local integration with `GrayImage`/`RgbImage`, tests, and compatibility updates for the current MoonBit toolchain.

## Apache License 2.0

The full Apache License 2.0 text is included in [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt).
