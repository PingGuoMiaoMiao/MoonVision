# MoonVision

MoonVision is a MoonBit-native lightweight image processing and basic computer vision library.

The current `v2.0` line includes the core lightweight image-processing library:

- flat image containers: `GrayImage`, `RgbImage`
- PNG decode to `RgbImage` through a vendored adapter layer
- basic pixel operations: grayscale, threshold, Otsu threshold, adaptive threshold, invert, brightness, contrast
- convolution and neighborhood filters: box blur, gaussian blur, sharpen, median blur
- gray-image geometric transforms: nearest-neighbor resize, bilinear resize, horizontal flip, vertical flip, 90-degree rotation
- edge detection: Sobel X/Y, gradient magnitude, binary edge extraction, Canny, lightweight Hough line detection
- binary morphology: erosion, dilation, opening, closing, gradient, top hat, black hat
- connected components, contour hierarchy, contour statistics, shape analysis, distance transform, and bounding boxes
- histogram analysis: grayscale histogram, cumulative histogram, normalized histogram, histogram equalization
- template matching: grayscale sum-of-absolute-differences best match
- visual export: PNG bytes, SVG overlays, HTML reports

The `v1.5` bacteria-review workflow extends the demo layer with:

- a lightweight bacteria probe under `src/demo/bacteria_probe`
- a large-lesion clustering route derived from dark binary candidates
- a labeled-review script that rebuilds one native executable and reuses it across a batch
- label-level, size-bucket, and review-mode summaries for the current annotated bacteria set

## Module Layout

```text
src/
  image/           GrayImage, RgbImage, pixel access, gray transforms
  ops/             grayscale, threshold, otsu, adaptive threshold, brightness, contrast
  histogram/       grayscale histograms and histogram equalization
  filter/          convolution, box blur, gaussian blur, sharpen, median blur
  edge/            sobel, gradient magnitude, canny, hough lines
  morphology/      binary morphology operators and derived morphology
  components/      connected components, contours, distance transform, and bounding boxes
  match/           grayscale template matching
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
let smooth_resized = try! @image.resize_bilinear(gray, 8, 8)
let rotated = try! @image.rotate90_cw(gray)
let equalized = try! @histogram.equalize_histogram(gray)
let edges = try! @edge.gradient_magnitude(blurred)
let canny = try! @edge.canny_edges(blurred, 48, 96)
let lines = try! @edge.hough_lines(canny, vote_threshold=4, max_lines=8)
let blobs = try! @components.connected_components(binary, min_area=4)
let distances = try! @components.distance_transform_manhattan(binary)
let contours = try! @components.find_contours(binary)
let first_kind = @components.contour_kind(contours[0])
let first_parent = @components.contour_parent_index(contours[0])
let simplified = @components.approx_contour(contours[0], 1.0)
let hull = @components.convex_hull(contours[0])
let rect = @components.min_area_rect(contours[0])
let circularity = @components.contour_circularity(contours[0])
let solidity = @components.contour_solidity(contours[0])
let best_match = try! @match.match_template_sad(gray, gray)
ignore(adaptive)
ignore(denoised)
ignore(resized)
ignore(smooth_resized)
ignore(rotated)
ignore(equalized)
ignore(edges)
ignore(canny)
ignore(lines)
ignore(blobs)
ignore(distances)
ignore(contours)
ignore(first_kind)
ignore(first_parent)
ignore(simplified)
ignore(hull)
ignore(rect)
ignore(circularity)
ignore(solidity)
ignore(best_match)
```

`find_contours` returns ordered boundary walks for binary foreground regions, along with area, perimeter, bounding-box, outer/hole kind, and optional parent-contour metadata.
In `v1.3`, contours are returned per traced boundary instead of per connected foreground region.
In `v1.4`, the same contour objects feed shape-analysis helpers for approximation, convex hulls, rotated rectangles, and lightweight descriptors.

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
- `examples/output/document_enhancement_equalized_v2_0.png`
- `examples/output/document_enhancement_output.png`
- `examples/output/document_enhancement_resized_v2_0.png`
- `examples/output/document_enhancement_report.html`

Bacteria labeled review:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -ForceRerun
```

For quick validation during parameter tuning, restrict the run to specific sample folders:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346
```

Exclude duplicated `rename` folders when checking the original reviewed images:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346 -ExcludeRenameCopies
```

Or cap the number of reviewed images:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -MaxImages 3
```

Outputs:

- `examples/output/bacteria_labeled_review/index.html`
- `examples/output/bacteria_labeled_review/summary_readable.csv`
- `examples/output/bacteria_labeled_review/mode_summary.csv`
- `examples/output/bacteria_labeled_review/label_summary.csv`
- `examples/output/bacteria_labeled_review/size_summary.csv`

The `v1.5` review report includes the default F1-oriented result, a recall-oriented parameter set, and a precision-oriented parameter set for each image. This keeps high-recall probes visible without hiding their false-positive cost.

## Version Stages

- `v1.0`
  Focused on the first complete visual-analysis chain: image containers, thresholding, filtering, Sobel edges, binary morphology, connected components, and export.
- `v1.1`
  Focused on robustness improvements: Otsu thresholding, adaptive thresholding, median blur, and gray-image transforms.
- `v1.2`
  Focuses on edge and contour analysis: Canny edges, contour extraction, contour statistics, and upgraded edge/counting demos.
- `v1.3`
  Refines contour semantics into outer/hole-aware hierarchy output, with deterministic parent-child relationships for nested structures.
- `v1.4`
  Extends the contour layer into lightweight shape analysis with contour approximation, convex hull extraction, minimum-area rotated rectangles, and descriptor helpers.
- `v1.5`
  Focuses on the labeled bacteria-review path: high-recall probe routes, native executable reuse during batch review, quick sample filtering, and multi-mode reporting by F1, recall, and precision.
- `v2.0`
  Expands the lightweight `imgproc` layer with histograms, histogram equalization, extended morphology, distance transform, Hough line detection, grayscale template matching, and bilinear resize.

## v1.0 vs v1.1 vs v1.2 vs v1.3 vs v1.4 vs v1.5 vs v2.0

The bundled demo assets are kept stable so `v1.0`, `v1.1`, `v1.2`, `v1.3`, and `v1.4` remain directly comparable. `v1.5` adds a labeled-review workflow for local annotated bacteria images, so its review metrics depend on the dataset selected by the script's `InputRoot` parameter. `v2.0` expands the reusable algorithm layer while preserving the existing demo commands.

- Object counting:
  `v1.0` used `threshold(120)` and detected `5` objects on the bundled asset.
  `v1.1` uses `median_blur(radius=1) -> otsu_threshold` and also detects `5` objects, while removing the fixed threshold constant from the counting path.
  `v1.2` keeps the `v1.1` binary path and adds ordered contour tracing plus a rendered contour mask for the same binary image.
  `v1.3` keeps the `v1.1` binary path, reports outer contours and hole contours separately, and labels the rendered contour mask as hierarchy-aware output.
  `v1.4` keeps the `v1.3` hierarchy output and adds shape-summary metrics for contour approximation, convex hulls, rotated rectangles, and solidity-style compactness.
- Edge detection:
  `v1.1` exported the Sobel gradient magnitude edge map.
  `v1.2` keeps that output and adds a binary `Canny` edge map for direct comparison.
- Document enhancement:
  `v1.0` used a fixed threshold after brightness and contrast adjustment.
  `v1.1` preserves the `v1.0` output in `document_enhancement_output_v1_0.png` and writes the optimized `median_blur -> adaptive_threshold_mean` result to `document_enhancement_output.png`.
  `v2.0` adds `document_enhancement_equalized_v2_0.png` for histogram-equalized contrast preview and `document_enhancement_resized_v2_0.png` for bilinear-resized output.
- Bacteria labeled review:
  `v1.5` keeps all core library APIs unchanged and extends the demo layer with batch review, per-preset scoring, best-alignment overlays, label and size summaries, and mode-level comparison across F1-oriented, recall-oriented, and precision-oriented selections.
  `v2.0` does not change the bacteria-review semantics; it keeps that workflow focused on reporting and validation.

## v1.5 Review Validation

Quick script validation without a full batch run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346
```

Original-image-only validation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346 -ExcludeRenameCopies
```

Small smoke run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -MaxImages 3
```

Full labeled review:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -ForceRerun
```

Use `mode_summary.csv` for the shortest top-level comparison, `summary_readable.csv` for per-image details, and each sample's `preset_scores.csv` for parameter-level debugging.

## Final Verification Checklist

Run the core checks:

```powershell
moon check
moon test
```

Run the bundled visual demos:

```powershell
moon run src/demo/object_counting
moon run src/demo/edge_detection
moon run src/demo/document_enhancement
```

Expected bundled demo reports:

- `examples/output/object_counting_report.html`
- `examples/output/edge_detection_report.html`
- `examples/output/document_enhancement_report.html`

Run the bacteria review workflow against local labeled data:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346 -ExcludeRenameCopies
```

Use `-ForceRerun` only when regenerating the full labeled review from the source images.

## Testing Scope

Current tests cover:

- image container invariants
- gray-image geometric transforms
- histogram analysis and histogram equalization
- PNG decode adaptation to `RgbImage`
- grayscale, global thresholding, Otsu thresholding, and adaptive thresholding
- filtering, border handling, and median blur behavior
- Sobel and Canny edge behavior
- Hough line detection behavior
- binary morphology behavior and derived morphology operators
- connected components, contour hierarchy, and contour statistics
- binary distance transform behavior
- contour approximation, convex hulls, rotated rectangles, and shape descriptors
- grayscale template matching
- SVG/HTML export rendering
- PNG signature generation

## Notes

- The project intentionally focuses on the algorithm layer. It does not provide GUI features, video processing, OpenCV bindings, or machine learning integration.
- PNG decode and export are implemented locally from vendored subsets adapted from `mizchi/image` and `mizchi/zlib`, because the current upstream registry dependency graph is not compatible with the local MoonBit toolchain used for this repository.

## License

MoonVision is released under the `MIT` license. See [LICENSE](LICENSE) for the full text.
