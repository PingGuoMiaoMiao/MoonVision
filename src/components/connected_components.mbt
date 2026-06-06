struct BoundingBox {
  x : Int
  y : Int
  width : Int
  height : Int
} derive(Eq, Show)

struct Component {
  label_id : Int
  bbox : BoundingBox
  area : Int
} derive(Eq, Show)

fn find_root(parents : Array[Int], label : Int) -> Int {
  let mut root = label
  while parents[root] != root {
    root = parents[root]
  }
  let mut current = label
  while parents[current] != current {
    let next = parents[current]
    parents[current] = root
    current = next
  }
  root
}

fn union_labels(parents : Array[Int], ranks : Array[Int], left : Int, right : Int) -> Unit {
  let left_root = find_root(parents, left)
  let right_root = find_root(parents, right)
  if left_root == right_root {
    return
  }
  if ranks[left_root] < ranks[right_root] {
    parents[left_root] = right_root
  } else if ranks[left_root] > ranks[right_root] {
    parents[right_root] = left_root
  } else {
    parents[right_root] = left_root
    ranks[left_root] = ranks[left_root] + 1
  }
}

fn pixel_is_foreground(img : @image.GrayImage, x : Int, y : Int) -> Bool raise @image.ImageError {
  img.get(x, y) != b'\x00'
}

fn scan_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

///|
pub fn connected_components(
  img : @image.GrayImage,
  min_area? : Int = 1,
) -> Array[Component] raise @image.ImageError {
  if min_area < 1 {
    raise @image.InvalidDimensions("min_area must be greater than or equal to one")
  }

  let labels = Array::make(img.pixel_count(), 0)
  let parents = [0]
  let ranks = [0]
  let mut next_label = 1

  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      if !pixel_is_foreground(img, x, y) {
        continue
      }

      let neighbor_labels = []
      if x > 0 {
        let left = labels[scan_index(img.width(), x - 1, y)]
        if left != 0 {
          neighbor_labels.push(left)
        }
      }
      if y > 0 {
        let up = labels[scan_index(img.width(), x, y - 1)]
        if up != 0 {
          neighbor_labels.push(up)
        }
        if x > 0 {
          let up_left = labels[scan_index(img.width(), x - 1, y - 1)]
          if up_left != 0 {
            neighbor_labels.push(up_left)
          }
        }
        if x + 1 < img.width() {
          let up_right = labels[scan_index(img.width(), x + 1, y - 1)]
          if up_right != 0 {
            neighbor_labels.push(up_right)
          }
        }
      }

      let index = scan_index(img.width(), x, y)
      if neighbor_labels.length() == 0 {
        labels[index] = next_label
        parents.push(next_label)
        ranks.push(0)
        next_label = next_label + 1
      } else {
        let base = neighbor_labels[0]
        labels[index] = base
        for i = 1; i < neighbor_labels.length(); i = i + 1 {
          union_labels(parents, ranks, base, neighbor_labels[i])
        }
      }
    }
  }

  let root_to_component = Array::make(next_label, -1)
  let label_ids = []
  let min_xs = []
  let min_ys = []
  let max_xs = []
  let max_ys = []
  let areas = []

  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let index = scan_index(img.width(), x, y)
      let label = labels[index]
      if label == 0 {
        continue
      }
      let root = find_root(parents, label)
      labels[index] = root
      let component_index = root_to_component[root]
      if component_index == -1 {
        root_to_component[root] = label_ids.length()
        label_ids.push(root)
        min_xs.push(x)
        min_ys.push(y)
        max_xs.push(x)
        max_ys.push(y)
        areas.push(1)
      } else {
        if x < min_xs[component_index] {
          min_xs[component_index] = x
        }
        if y < min_ys[component_index] {
          min_ys[component_index] = y
        }
        if x > max_xs[component_index] {
          max_xs[component_index] = x
        }
        if y > max_ys[component_index] {
          max_ys[component_index] = y
        }
        areas[component_index] = areas[component_index] + 1
      }
    }
  }

  let components = []
  for i = 0; i < label_ids.length(); i = i + 1 {
    if areas[i] >= min_area {
      components.push({
        label_id: label_ids[i],
        bbox: {
          x: min_xs[i],
          y: min_ys[i],
          width: max_xs[i] - min_xs[i] + 1,
          height: max_ys[i] - min_ys[i] + 1,
        },
        area: areas[i],
      })
    }
  }
  components
}

///|
pub fn Component::label_id(self : Component) -> Int {
  self.label_id
}

///|
pub fn Component::area(self : Component) -> Int {
  self.area
}

///|
pub fn Component::bbox(self : Component) -> BoundingBox {
  self.bbox
}

///|
pub fn BoundingBox::x(self : BoundingBox) -> Int {
  self.x
}

///|
pub fn BoundingBox::y(self : BoundingBox) -> Int {
  self.y
}

///|
pub fn BoundingBox::width(self : BoundingBox) -> Int {
  self.width
}

///|
pub fn BoundingBox::height(self : BoundingBox) -> Int {
  self.height
}
