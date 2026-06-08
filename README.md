# MoonVision

MoonVision is a MoonBit-native lightweight image processing and basic computer vision library.

The current `v1.0` line focuses on:

- flat image containers: `GrayImage`, `RgbImage`
- PNG decode to `RgbImage` through a vendored adapter layer
- basic pixel operations: grayscale, threshold, invert, brightness, contrast
- convolution filters: box blur, gaussian blur, sharpen
- edge detection: Sobel X/Y, gradient magnitude, binary edge extraction
- binary morphology: erosion, dilation, opening, closing
- connected components with bounding boxes and minimum-area filtering
- visual export: PNG bytes, SVG overlays, HTML reports

## Module Layout

```text
src/
  image/           GrayImage, RgbImage, pixel access
  ops/             grayscale, threshold, invert, brightness, contrast
  filter/          convolution, box blur, gaussian blur, sharpen
  edge/            sobel and gradient magnitude
  morphology/      binary morphology operators
  components/      connected components and bounding boxes
  export/          PNG encoding, SVG overlays, HTML reports
  demo_support/    demo-only file writing helpers
  demo/            runnable demo packages
```

## Quick Start

Check the project:

```powershell
moon check
```

Run tests:

```powershell
moon test --target js
```

At the time of writing, the repository test suite is verified with the JS target.

## Basic Usage

```moonbit
let rgb = try! @image.rgb(4, 4)
let gray = try! @ops.grayscale(rgb)
let binary = try! @ops.threshold(gray, 128)
let blurred = try! @filter.gaussian_blur(gray, radius=1)
let edges = try! @edge.gradient_magnitude(blurred)
let blobs = try! @components.connected_components(binary, min_area=4)
ignore(edges)
ignore(blobs)
```

Export a grayscale image as PNG bytes:

```moonbit
let png = @export.encode_gray_png(binary)
ignore(png)
```

Build an SVG overlay for detected components:

```moonbit
let overlay = @export.svg_bounding_boxes(
  binary.width(),
  binary.height(),
  blobs,
)
ignore(overlay)
```

Decode a PNG file into `RgbImage` bytes first:

```moonbit
let input = try! @image.rgb_from_png_bytes(png_bytes)
ignore(input)
```

## Demos

Demo input assets live in `examples/assets/`.

All demo outputs are written to `examples/output/`.

Object counting:

```powershell
moon run --target js src/demo/object_counting
```

Outputs:

- `examples/output/object_counting_input.png`
- `examples/output/object_counting_binary.png`
- `examples/output/object_counting_overlay.svg`
- `examples/output/object_counting_report.html`

Edge detection:

```powershell
moon run --target js src/demo/edge_detection
```

Outputs:

- `examples/output/edge_detection_input.png`
- `examples/output/edge_detection_edges.png`
- `examples/output/edge_detection_report.html`

Document enhancement:

```powershell
moon run --target js src/demo/document_enhancement
```

Outputs:

- `examples/output/document_enhancement_input.png`
- `examples/output/document_enhancement_output.png`
- `examples/output/document_enhancement_report.html`

## Testing Scope

Current tests cover:

- image container invariants
- PNG decode adaptation to `RgbImage`
- grayscale and pixel-level ops
- filtering and border handling
- Sobel gradient behavior
- binary morphology behavior
- connected components and area filtering
- SVG/HTML export rendering
- PNG signature generation

## Notes

- The project intentionally focuses on the algorithm layer. It does not provide GUI features, video processing, OpenCV bindings, or machine learning integration.
- PNG decode and export are implemented locally from vendored subsets adapted from `mizchi/image` and `mizchi/zlib`, because the current upstream registry dependency graph is not compatible with the local MoonBit toolchain used for this repository.

## License

MoonVision is released under the `MIT` license. See [LICENSE](/C:/Users/chen/Desktop/MoonVision/LICENSE) for the full text.
