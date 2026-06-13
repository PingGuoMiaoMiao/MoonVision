# MoonVision

MoonVision is a MoonBit-native lightweight image processing and basic computer vision library.

The current `v1.2` line focuses on:

- flat image containers: `GrayImage`, `RgbImage`
- PNG decode to `RgbImage` through a vendored adapter layer
- basic pixel operations: grayscale, threshold, Otsu threshold, adaptive threshold, invert, brightness, contrast
- convolution and neighborhood filters: box blur, gaussian blur, sharpen, median blur
- gray-image geometric transforms: nearest-neighbor resize, horizontal flip, vertical flip, 90-degree rotation
- edge detection: Sobel X/Y, gradient magnitude, binary edge extraction, Canny
- binary morphology: erosion, dilation, opening, closing
- connected components, ordered contour extraction, contour statistics, and bounding boxes
- visual export: PNG bytes, SVG overlays, HTML reports

## Module Layout

```text
src/
  image/           GrayImage, RgbImage, pixel access, gray transforms
  ops/             grayscale, threshold, otsu, adaptive threshold, brightness, contrast
  filter/          convolution, box blur, gaussian blur, sharpen, median blur
  edge/            sobel, gradient magnitude, canny
  morphology/      binary morphology operators
  components/      connected components, contours, and bounding boxes
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
moon test
```

At the time of writing, the repository test suite passes on the repository default target.

## Basic Usage

```moonbit
let rgb = try! @image.rgb(4, 4)
let gray = try! @ops.grayscale(rgb)
let binary = try! @ops.otsu_threshold(gray)
let adaptive = try! @ops.adaptive_threshold_mean(gray, 5, 7)
let denoised = try! @filter.median_blur(gray, radius=1)
let blurred = try! @filter.gaussian_blur(gray, radius=1)
let resized = try! @image.resize_nearest(gray, 8, 8)
let rotated = try! @image.rotate90_cw(gray)
let edges = try! @edge.gradient_magnitude(blurred)
let canny = try! @edge.canny_edges(blurred, 48, 96)
let blobs = try! @components.connected_components(binary, min_area=4)
let contours = try! @components.find_contours(binary)
ignore(adaptive)
ignore(denoised)
ignore(resized)
ignore(rotated)
ignore(edges)
ignore(canny)
ignore(blobs)
ignore(contours)
```

`find_contours` returns ordered boundary walks for binary foreground regions, along with area, perimeter, and bounding-box statistics for the traced region.

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
moon run src/demo/object_counting
```

Outputs:

- `examples/output/object_counting_input.png`
- `examples/output/object_counting_binary_v1_0.png`
- `examples/output/object_counting_binary.png`
- `examples/output/object_counting_contours.png`
- `examples/output/object_counting_overlay.svg`
- `examples/output/object_counting_report.html`

Edge detection:

```powershell
moon run src/demo/edge_detection
```

Outputs:

- `examples/output/edge_detection_input.png`
- `examples/output/edge_detection_edges.png`
- `examples/output/edge_detection_canny.png`
- `examples/output/edge_detection_report.html`

Document enhancement:

```powershell
moon run src/demo/document_enhancement
```

Outputs:

- `examples/output/document_enhancement_input.png`
- `examples/output/document_enhancement_output_v1_0.png`
- `examples/output/document_enhancement_output.png`
- `examples/output/document_enhancement_report.html`

## Version Stages

- `v1.0`
  Focused on the first complete visual-analysis chain: image containers, thresholding, filtering, Sobel edges, binary morphology, connected components, and export.
- `v1.1`
  Focused on robustness improvements: Otsu thresholding, adaptive thresholding, median blur, and gray-image transforms.
- `v1.2`
  Focuses on edge and contour analysis: Canny edges, contour extraction, contour statistics, and upgraded edge/counting demos.

## v1.0 vs v1.1 vs v1.2

The bundled demo assets are kept stable so `v1.0`, `v1.1`, and `v1.2` remain directly comparable.

- Object counting:
  `v1.0` used `threshold(120)` and detected `5` objects on the bundled asset.
  `v1.1` uses `median_blur(radius=1) -> otsu_threshold` and also detects `5` objects, while removing the fixed threshold constant from the counting path.
  `v1.2` keeps the `v1.1` binary path and adds ordered contour tracing plus a rendered contour mask for the same binary image.
- Edge detection:
  `v1.1` exported the Sobel gradient magnitude edge map.
  `v1.2` keeps that output and adds a binary `Canny` edge map for direct comparison.
- Document enhancement:
  `v1.0` used a fixed threshold after brightness and contrast adjustment.
  `v1.1` preserves the `v1.0` output in `document_enhancement_output_v1_0.png` and writes the optimized `median_blur -> adaptive_threshold_mean` result to `document_enhancement_output.png`.

## Testing Scope

Current tests cover:

- image container invariants
- gray-image geometric transforms
- PNG decode adaptation to `RgbImage`
- grayscale, global thresholding, Otsu thresholding, and adaptive thresholding
- filtering, border handling, and median blur behavior
- Sobel and Canny edge behavior
- binary morphology behavior
- connected components, ordered contour extraction, and contour statistics
- SVG/HTML export rendering
- PNG signature generation

## Notes

- The project intentionally focuses on the algorithm layer. It does not provide GUI features, video processing, OpenCV bindings, or machine learning integration.
- PNG decode and export are implemented locally from vendored subsets adapted from `mizchi/image` and `mizchi/zlib`, because the current upstream registry dependency graph is not compatible with the local MoonBit toolchain used for this repository.

## License

MoonVision is released under the `MIT` license. See [LICENSE](/C:/Users/chen/Desktop/MoonVision/LICENSE) for the full text.
