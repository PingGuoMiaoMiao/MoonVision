let output_dir = "examples/output/bacteria_probe/current/"
let asset_path = "examples/runtime/bacteria_probe_input.png"
let roi_threshold = 8
let write_debug_rasters = false

struct ProbePreset {
  name : String
  invert_mask : Bool
  brightness_delta : Int
  contrast_factor : Double
  roi_margin_divisor : Int
  roi_min_margin : Int
  roi_max_margin : Int
  open_radius : Int
  close_radius : Int
  min_area : Int
  max_area : Int
  max_aspect_x100 : Int
  min_fill_x1000 : Int
  edge_margin : Int
  merge_gap : Int
  min_cluster_boxes : Int
  min_cluster_bbox_area : Int
  cluster_only : Bool
  reuse_previous_candidates : Bool
  shrink_x100 : Int
  shrink_max_bbox_area : Int
} derive(Eq, Show)

struct ProbeRoi {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Show)

struct DetectedBox {
  x : Int
  y : Int
  width : Int
  height : Int
  area : Int
} derive(Eq, Show)

fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn crop_gray(img : @image.GrayImage, roi : ProbeRoi) -> @image.GrayImage {
  let cropped = try! @image.gray(roi.width, roi.height)
  for y = 0; y < roi.height; y = y + 1 {
    for x = 0; x < roi.width; x = x + 1 {
      try! cropped.set(x, y, try! img.get(roi.x + x, roi.y + y))
    }
  }
  cropped
}

fn crop_rgb(img : @image.RgbImage, roi : ProbeRoi) -> @image.RgbImage {
  let cropped = try! @image.rgb(roi.width, roi.height)
  for y = 0; y < roi.height; y = y + 1 {
    for x = 0; x < roi.width; x = x + 1 {
      try! cropped.set(x, y, try! img.get(roi.x + x, roi.y + y))
    }
  }
  cropped
}

fn detect_non_black_bounds(gray : @image.GrayImage) -> ProbeRoi {
  let mut found = false
  let mut min_x = gray.width()
  let mut min_y = gray.height()
  let mut max_x = 0
  let mut max_y = 0
  for y = 0; y < gray.height(); y = y + 1 {
    for x = 0; x < gray.width(); x = x + 1 {
      if (try! gray.get(x, y)).to_int() <= roi_threshold {
        continue
      }
      if !found {
        found = true
        min_x = x
        min_y = y
        max_x = x
        max_y = y
      } else {
        if x < min_x {
          min_x = x
        }
        if y < min_y {
          min_y = y
        }
        if x > max_x {
          max_x = x
        }
        if y > max_y {
          max_y = y
        }
      }
    }
  }
  if !found {
    return { x: 0, y: 0, width: gray.width(), height: gray.height() }
  }

  { x: min_x, y: min_y, width: max_x - min_x + 1, height: max_y - min_y + 1 }
}

fn apply_roi_margin(
  roi : ProbeRoi,
  margin_divisor : Int,
  min_margin : Int,
  max_margin : Int,
) -> ProbeRoi {
  if margin_divisor <= 0 {
    return roi
  }
  let inset_x = min_int(max_margin, max_int(min_margin, roi.width / margin_divisor))
  let inset_y = min_int(max_margin, max_int(min_margin, roi.height / margin_divisor))
  let next_x = roi.x + inset_x
  let next_y = roi.y + inset_y
  let next_width = roi.width - inset_x * 2
  let next_height = roi.height - inset_y * 2
  if next_width > 0 && next_height > 0 {
    { x: next_x, y: next_y, width: next_width, height: next_height }
  } else {
    roi
  }
}

fn detect_non_black_roi(gray : @image.GrayImage, preset : ProbePreset) -> ProbeRoi {
  apply_roi_margin(
    detect_non_black_bounds(gray),
    preset.roi_margin_divisor,
    preset.roi_min_margin,
    preset.roi_max_margin,
  )
}

fn roi_svg(width : Int, height : Int, roi : ProbeRoi) -> String {
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
  width.to_string() +
  " " +
  height.to_string() +
  "\" width=\"" +
  width.to_string() +
  "\" height=\"" +
  height.to_string() +
  "\">\n" +
  "  <rect x=\"" +
  roi.x.to_string() +
  "\" y=\"" +
  roi.y.to_string() +
  "\" width=\"" +
  roi.width.to_string() +
  "\" height=\"" +
  roi.height.to_string() +
  "\" fill=\"none\" stroke=\"#2563eb\" stroke-width=\"4\" />\n" +
  "</svg>"
}

fn preset_mask(contrasted : @image.GrayImage, preset : ProbePreset) -> @image.GrayImage {
  let base = try! @ops.otsu_threshold(contrasted)
  let thresholded = if preset.invert_mask {
    try! @ops.invert(base)
  } else {
    base
  }
  let opened = try! @morphology.open_binary(thresholded, radius=preset.open_radius)
  try! @morphology.close_binary(opened, radius=preset.close_radius)
}

fn aspect_ratio_x100(width : Int, height : Int) -> Int {
  if width <= 0 || height <= 0 {
    0
  } else if width >= height {
    width * 100 / height
  } else {
    height * 100 / width
  }
}

fn fill_ratio_x1000(area : Int, width : Int, height : Int) -> Int {
  let bbox_area = width * height
  if bbox_area <= 0 {
    0
  } else {
    area * 1000 / bbox_area
  }
}

fn touches_roi_edge(
  local_x : Int,
  local_y : Int,
  width : Int,
  height : Int,
  roi_width : Int,
  roi_height : Int,
  edge_margin : Int,
) -> Bool {
  local_x <= edge_margin ||
  local_y <= edge_margin ||
  local_x + width >= roi_width - edge_margin ||
  local_y + height >= roi_height - edge_margin
}

fn filter_boxes(
  components : Array[@components.Component],
  roi : ProbeRoi,
  preset : ProbePreset,
) -> Array[DetectedBox] {
  let boxes = []
  for component in components {
    let bbox = component.bbox()
    let width = bbox.width()
    let height = bbox.height()
    let area = component.area()
    if area < preset.min_area || area > preset.max_area {
      continue
    }
    if touches_roi_edge(
      bbox.x(),
      bbox.y(),
      width,
      height,
      roi.width,
      roi.height,
      preset.edge_margin,
    ) {
      continue
    }
    if aspect_ratio_x100(width, height) > preset.max_aspect_x100 {
      continue
    }
    if fill_ratio_x1000(area, width, height) < preset.min_fill_x1000 {
      continue
    }
    boxes.push({
      x: roi.x + bbox.x(),
      y: roi.y + bbox.y(),
      width,
      height,
      area,
    })
  }
  boxes
}

fn boxes_overlap_or_close(left : DetectedBox, right : DetectedBox, gap : Int) -> Bool {
  let left_x1 = left.x - gap
  let left_y1 = left.y - gap
  let left_x2 = left.x + left.width + gap
  let left_y2 = left.y + left.height + gap
  let right_x1 = right.x - gap
  let right_y1 = right.y - gap
  let right_x2 = right.x + right.width + gap
  let right_y2 = right.y + right.height + gap
  left_x1 < right_x2 &&
  left_x2 > right_x1 &&
  left_y1 < right_y2 &&
  left_y2 > right_y1
}

fn merged_cluster_box(
  boxes : Array[DetectedBox],
  cluster_indices : Array[Int],
) -> DetectedBox {
  let first = boxes[cluster_indices[0]]
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x + first.width
  let mut max_y = first.y + first.height
  let mut total_area = 0
  for index in cluster_indices {
    let box = boxes[index]
    if box.x < min_x {
      min_x = box.x
    }
    if box.y < min_y {
      min_y = box.y
    }
    if box.x + box.width > max_x {
      max_x = box.x + box.width
    }
    if box.y + box.height > max_y {
      max_y = box.y + box.height
    }
    total_area = total_area + box.area
  }
  {
    x: min_x,
    y: min_y,
    width: max_x - min_x,
    height: max_y - min_y,
    area: total_area,
  }
}

fn keep_cluster_box(box : DetectedBox, preset : ProbePreset) -> Bool {
  let bbox_area = box.width * box.height
  bbox_area >= preset.min_cluster_bbox_area &&
  aspect_ratio_x100(box.width, box.height) <= preset.max_aspect_x100 &&
  fill_ratio_x1000(box.area, box.width, box.height) >= preset.min_fill_x1000
}

fn cluster_boxes(boxes : Array[DetectedBox], preset : ProbePreset) -> Array[DetectedBox] {
  if preset.merge_gap <= 0 || preset.min_cluster_boxes <= 1 || boxes.length() == 0 {
    return []
  }
  let visited = Array::make(boxes.length(), false)
  let merged = []
  for i = 0; i < boxes.length(); i = i + 1 {
    if visited[i] {
      continue
    }
    visited[i] = true
    let pending = [i]
    let cluster = []
    let mut cursor = 0
    while cursor < pending.length() {
      let current = pending[cursor]
      cursor = cursor + 1
      cluster.push(current)
      for j = 0; j < boxes.length(); j = j + 1 {
        if visited[j] {
          continue
        }
        if boxes_overlap_or_close(boxes[current], boxes[j], preset.merge_gap) {
          visited[j] = true
          pending.push(j)
        }
      }
    }
    if cluster.length() < preset.min_cluster_boxes {
      continue
    }
    let merged_box = merged_cluster_box(boxes, cluster)
    if keep_cluster_box(merged_box, preset) {
      merged.push(merged_box)
    }
  }
  merged
}

fn output_boxes(candidate_boxes : Array[DetectedBox], preset : ProbePreset) -> Array[DetectedBox] {
  let merged_boxes = cluster_boxes(candidate_boxes, preset)
  let raw_boxes = if preset.cluster_only {
    merged_boxes
  } else if preset.merge_gap > 0 && merged_boxes.length() > 0 {
    let combined = []
    for box in candidate_boxes {
      combined.push(box)
    }
    for box in merged_boxes {
      combined.push(box)
    }
    combined
  } else {
    candidate_boxes
  }
  let base_boxes = if preset.shrink_max_bbox_area > 0 {
    let filtered = []
    for box in raw_boxes {
      if box.width * box.height <= preset.shrink_max_bbox_area {
        filtered.push(box)
      }
    }
    filtered
  } else {
    raw_boxes
  }
  if preset.shrink_x100 <= 0 || preset.shrink_x100 == 100 {
    return base_boxes
  }
  // Historical note: `shrink_x100` now behaves like a center-preserving box
  // scale. Existing routes still use values below 100 for tightening, while
  // expanded routes use values above 100 to recover near-miss overlaps.
  let shrink_boxes = []
  for box in base_boxes {
    let next_width = max_int(1, box.width * preset.shrink_x100 / 100)
    let next_height = max_int(1, box.height * preset.shrink_x100 / 100)
    let next_x = box.x + (box.width - next_width) / 2
    let next_y = box.y + (box.height - next_height) / 2
    shrink_boxes.push({
      x: next_x,
      y: next_y,
      width: next_width,
      height: next_height,
      area: box.area,
    })
  }
  shrink_boxes
}

fn boxes_svg(
  width : Int,
  height : Int,
  boxes : Array[DetectedBox],
  title : String,
  color : String,
) -> String {
  let mut out =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    width.to_string() +
    " " +
    height.to_string() +
    "\" width=\"" +
    width.to_string() +
    "\" height=\"" +
    height.to_string() +
    "\">\n  <title>" +
    title +
    "</title>\n"
  for i = 0; i < boxes.length(); i = i + 1 {
    let box = boxes[i]
    out = out +
      "  <rect x=\"" +
      box.x.to_string() +
      "\" y=\"" +
      box.y.to_string() +
      "\" width=\"" +
      box.width.to_string() +
      "\" height=\"" +
      box.height.to_string() +
      "\" fill=\"none\" stroke=\"" +
      color +
      "\" stroke-width=\"4\" />\n" +
      "  <text x=\"" +
      box.x.to_string() +
      "\" y=\"" +
      max_int(20, box.y - 6).to_string() +
      "\" fill=\"" +
      color +
      "\" font-size=\"24\">box " +
      i.to_string() +
      " area=" +
      box.area.to_string() +
      "</text>\n"
  }
  out + "</svg>"
}

fn boxes_csv(boxes : Array[DetectedBox]) -> String {
  let mut out = "x,y,width,height,area\n"
  for box in boxes {
    out = out +
      box.x.to_string() +
      "," +
      box.y.to_string() +
      "," +
      box.width.to_string() +
      "," +
      box.height.to_string() +
      "," +
      box.area.to_string() +
      "\n"
  }
  out
}

fn roi_csv(roi : ProbeRoi) -> String {
  "x,y,width,height\n" +
  roi.x.to_string() +
  "," +
  roi.y.to_string() +
  "," +
  roi.width.to_string() +
  "," +
  roi.height.to_string() +
  "\n"
}

fn presets() -> Array[ProbePreset] {
  [
    {
      name: "light_small_tight",
      invert_mask: false,
      brightness_delta: 14,
      contrast_factor: 1.35,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 9000,
      max_area: 150000,
      max_aspect_x100: 280,
      min_fill_x1000: 150,
      edge_margin: 12,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_tight",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_tight_expanded_135",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 135,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_wide",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 0,
      roi_min_margin: 0,
      roi_max_margin: 0,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 0,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_wide_shrunk",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 0,
      roi_min_margin: 0,
      roi_max_margin: 0,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 0,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 90,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_wide_plus_cluster",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 0,
      roi_min_margin: 0,
      roi_max_margin: 0,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 0,
      merge_gap: 120,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 120000,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_wide_plus_cluster_expanded",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 0,
      roi_min_margin: 0,
      roi_max_margin: 0,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 0,
      merge_gap: 120,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 120000,
      cluster_only: false,
      reuse_previous_candidates: false,
      shrink_x100: 120,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_large_cluster",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 0,
      roi_min_margin: 0,
      roi_max_margin: 0,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 50,
      edge_margin: 0,
      merge_gap: 120,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 120000,
      cluster_only: true,
      reuse_previous_candidates: true,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_plus_cluster",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 120,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 120000,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_plus_cluster_expanded",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 120,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 120000,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 120,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_plus_cluster_tight",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 40,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 80000,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 100,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_plus_cluster_tight_expanded",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 40,
      min_cluster_boxes: 2,
      min_cluster_bbox_area: 80000,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 120,
      shrink_max_bbox_area: 0,
    },
    {
      name: "dark_small_shrunk",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 90,
      shrink_max_bbox_area: 120000,
    },
    {
      name: "dark_small_shrunk_expanded_140",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 140,
      shrink_max_bbox_area: 120000,
    },
    {
      name: "dark_small_filtered",
      invert_mask: true,
      brightness_delta: 10,
      contrast_factor: 1.20,
      roi_margin_divisor: 25,
      roi_min_margin: 16,
      roi_max_margin: 80,
      open_radius: 1,
      close_radius: 1,
      min_area: 1500,
      max_area: 90000,
      max_aspect_x100: 320,
      min_fill_x1000: 90,
      edge_margin: 8,
      merge_gap: 0,
      min_cluster_boxes: 0,
      min_cluster_bbox_area: 0,
      cluster_only: false,
      reuse_previous_candidates: true,
      shrink_x100: 100,
      shrink_max_bbox_area: 40000,
    },
  ]
}

fn main {
  let all_presets = presets()
  let input = try! @image.rgb_from_png_bytes(try! @demoio.read_bytes_from_file(asset_path))
  let gray = try! @ops.grayscale(input)
  let mut cached_dark_small_roi = { x: 0, y: 0, width: gray.width(), height: gray.height() }
  let mut cached_dark_small_boxes = []
  let report_images = []
  let report_lines = [
    "input asset: " + asset_path,
    "input size: " + input.width().to_string() + "x" + input.height().to_string(),
    "write_debug_rasters: " + write_debug_rasters.to_string(),
  ]

  if write_debug_rasters {
    write_rgb_png(output_dir + "input.png", input)
    write_gray_png(output_dir + "gray.png", gray)
    report_images.push(@export.report_image("input", "input.png"))
    report_images.push(@export.report_image("gray", "gray.png"))
  }

  for i = 0; i < all_presets.length(); i = i + 1 {
    let preset = all_presets[i]
    let roi = if preset.reuse_previous_candidates {
      cached_dark_small_roi
    } else {
      detect_non_black_roi(gray, preset)
    }
    let input_roi_name = preset.name + "_input_roi.png"
    let gray_roi_name = preset.name + "_gray_roi.png"
    let roi_csv_name = preset.name + "_roi.csv"
    let roi_overlay_name = preset.name + "_roi_overlay.svg"
    let overlay_name = preset.name + "_overlay.svg"
    let boxes_name = preset.name + "_boxes.csv"

    let candidate_boxes = if preset.reuse_previous_candidates {
      cached_dark_small_boxes
    } else {
      let gray_roi = crop_gray(gray, roi)
      let input_roi = crop_rgb(input, roi)
      let adjusted = try! @ops.adjust_brightness(gray_roi, preset.brightness_delta)
      let contrasted = try! @ops.adjust_contrast(adjusted, preset.contrast_factor)
      let mask = preset_mask(contrasted, preset)
      let components = try! @components.connected_components(mask, min_area=1)
      let next_boxes = filter_boxes(components, roi, preset)
      let contrasted_name = preset.name + "_contrasted.png"
      let mask_name = preset.name + "_mask.png"

      if write_debug_rasters {
        write_rgb_png(output_dir + input_roi_name, input_roi)
        write_gray_png(output_dir + gray_roi_name, gray_roi)
        write_gray_png(output_dir + contrasted_name, contrasted)
        write_gray_png(output_dir + mask_name, mask)
        report_images.push(@export.report_image(preset.name + " input roi", input_roi_name))
        report_images.push(@export.report_image(preset.name + " contrasted", contrasted_name))
        report_images.push(@export.report_image(preset.name + " mask", mask_name))
      }

      if preset.name == "dark_small_tight" {
        cached_dark_small_roi = roi
        cached_dark_small_boxes = next_boxes
      }
      next_boxes
    }
    let merged_boxes = cluster_boxes(candidate_boxes, preset)
    let boxes = output_boxes(candidate_boxes, preset)
    try! @demoio.write_string_to_file(output_dir + roi_csv_name, roi_csv(roi))
    try! @demoio.write_string_to_file(
      output_dir + roi_overlay_name,
      roi_svg(input.width(), input.height(), roi),
    )
    try! @demoio.write_string_to_file(
      output_dir + overlay_name,
      boxes_svg(
        input.width(),
        input.height(),
        boxes,
        "MoonVision Bacteria Probe " + preset.name,
        if preset.invert_mask { "#dc2626" } else { "#2563eb" },
      ),
    )
    try! @demoio.write_string_to_file(output_dir + boxes_name, boxes_csv(boxes))

    report_lines.push(
      preset.name +
      ": boxes=" +
      boxes.length().to_string() +
      ", candidates=" +
      candidate_boxes.length().to_string() +
      ", merged=" +
      merged_boxes.length().to_string() +
      ", roi_margin_divisor=" +
      preset.roi_margin_divisor.to_string() +
      ", cluster_only=" +
      preset.cluster_only.to_string() +
      ", merge_gap=" +
      preset.merge_gap.to_string() +
      ", reuse_previous_candidates=" +
      preset.reuse_previous_candidates.to_string() +
      ", min_area=" +
      preset.min_area.to_string() +
      ", max_area=" +
      preset.max_area.to_string(),
    )
    report_lines.push(
      preset.name +
      " roi: x=" +
      roi.x.to_string() +
      ", y=" +
      roi.y.to_string() +
      ", width=" +
      roi.width.to_string() +
      ", height=" +
      roi.height.to_string(),
    )
    report_images.push(@export.report_image(preset.name + " roi overlay", roi_overlay_name))
    report_images.push(@export.report_image(preset.name + " overlay", overlay_name))
    println("preset=" + preset.name + ",boxes=" + boxes.length().to_string())
  }

  try! @demoio.write_string_to_file(
    output_dir + "report.html",
    @export.html_report("MoonVision Bacteria Probe", report_lines, report_images),
  )
  println("report=" + output_dir + "report.html")
}

fn cluster_preset_fixture() -> ProbePreset {
  {
    name: "cluster_fixture",
    invert_mask: true,
    brightness_delta: 0,
    contrast_factor: 1.0,
    roi_margin_divisor: 0,
    roi_min_margin: 0,
    roi_max_margin: 0,
    open_radius: 0,
    close_radius: 0,
    min_area: 0,
    max_area: 1000000,
    max_aspect_x100: 500,
    min_fill_x1000: 40,
    edge_margin: 0,
    merge_gap: 120,
    min_cluster_boxes: 2,
    min_cluster_bbox_area: 120000,
    cluster_only: true,
    reuse_previous_candidates: false,
    shrink_x100: 100,
    shrink_max_bbox_area: 0,
  }
}

///|
test "cluster boxes merges nearby fragments into a single large box" {
  let boxes = [
    { x: 1007, y: 275, width: 469, height: 320, area: 38436 },
    { x: 616, y: 706, width: 397, height: 713, area: 115558 },
    { x: 1189, y: 1628, width: 154, height: 160, area: 11999 },
  ]
  let merged = cluster_boxes(boxes, cluster_preset_fixture())
  inspect(merged.length(), content="1")
  inspect(merged[0].x, content="616")
  inspect(merged[0].y, content="275")
  inspect(merged[0].width, content="860")
  inspect(merged[0].height, content="1513")
}

///|
test "output boxes appends merged cluster box for hybrid route" {
  let boxes = [
    { x: 1007, y: 275, width: 469, height: 320, area: 38436 },
    { x: 616, y: 706, width: 397, height: 713, area: 115558 },
    { x: 1189, y: 1628, width: 154, height: 160, area: 11999 },
  ]
  let preset = {
    ..cluster_preset_fixture(),
    name: "hybrid_fixture",
    cluster_only: false,
  }
  let combined = output_boxes(boxes, preset)
  inspect(combined.length(), content="4")
  inspect(combined[3].x, content="616")
  inspect(combined[3].y, content="275")
  inspect(combined[3].width, content="860")
  inspect(combined[3].height, content="1513")
}

///|
test "output boxes shrinks qualifying boxes for shrunk route" {
  let boxes = [
    { x: 100, y: 200, width: 100, height: 50, area: 3000 },
    { x: 300, y: 400, width: 400, height: 200, area: 60000 },
  ]
  let preset = {
    ..cluster_preset_fixture(),
    name: "shrunk_fixture",
    cluster_only: false,
    merge_gap: 0,
    shrink_x100: 90,
    shrink_max_bbox_area: 120000,
  }
  let shrunk = output_boxes(boxes, preset)
  inspect(shrunk.length(), content="2")
  inspect(shrunk[0].x, content="105")
  inspect(shrunk[0].y, content="202")
  inspect(shrunk[0].width, content="90")
  inspect(shrunk[0].height, content="45")
  inspect(shrunk[1].x, content="320")
  inspect(shrunk[1].y, content="410")
  inspect(shrunk[1].width, content="360")
  inspect(shrunk[1].height, content="180")
}

///|
test "output boxes drops oversized boxes for shrunk route" {
  let boxes = [
    { x: 100, y: 200, width: 100, height: 50, area: 3000 },
    { x: 300, y: 400, width: 500, height: 400, area: 100000 },
  ]
  let preset = {
    ..cluster_preset_fixture(),
    name: "shrunk_limit_fixture",
    cluster_only: false,
    merge_gap: 0,
    shrink_x100: 90,
    shrink_max_bbox_area: 10000,
  }
  let shrunk = output_boxes(boxes, preset)
  inspect(shrunk.length(), content="1")
  inspect(shrunk[0].x, content="105")
  inspect(shrunk[0].y, content="202")
  inspect(shrunk[0].width, content="90")
  inspect(shrunk[0].height, content="45")
}

///|
test "output boxes expands boxes when scale is above one hundred" {
  let boxes = [
    { x: 100, y: 200, width: 100, height: 50, area: 3000 },
  ]
  let preset = {
    ..cluster_preset_fixture(),
    name: "expanded_fixture",
    cluster_only: false,
    merge_gap: 0,
    shrink_x100: 120,
  }
  let expanded = output_boxes(boxes, preset)
  inspect(expanded.length(), content="1")
  inspect(expanded[0].x, content="90")
  inspect(expanded[0].y, content="195")
  inspect(expanded[0].width, content="120")
  inspect(expanded[0].height, content="60")
}

///|
test "output boxes filters oversized boxes without shrinking" {
  let boxes = [
    { x: 100, y: 200, width: 100, height: 50, area: 3000 },
    { x: 300, y: 400, width: 500, height: 400, area: 100000 },
  ]
  let preset = {
    ..cluster_preset_fixture(),
    name: "filtered_fixture",
    cluster_only: false,
    merge_gap: 0,
    shrink_x100: 100,
    shrink_max_bbox_area: 10000,
  }
  let filtered = output_boxes(boxes, preset)
  inspect(filtered.length(), content="1")
  inspect(filtered[0].x, content="100")
  inspect(filtered[0].y, content="200")
  inspect(filtered[0].width, content="100")
  inspect(filtered[0].height, content="50")
}

///|
test "apply roi margin keeps bounds when divisor is zero" {
  let roi = apply_roi_margin({ x: 10, y: 20, width: 300, height: 200 }, 0, 0, 0)
  inspect(roi.x, content="10")
  inspect(roi.y, content="20")
  inspect(roi.width, content="300")
  inspect(roi.height, content="200")
}
