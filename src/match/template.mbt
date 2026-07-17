///|
struct TemplateMatch {
  x : Int
  y : Int
  score : Int
} derive(Eq)

///|
fn sad_at(
  source : @image.GrayImage,
  template : @image.GrayImage,
  origin_x : Int,
  origin_y : Int,
) -> Int raise @image.ImageError {
  let mut score = 0
  for y = 0; y < template.height(); y = y + 1 {
    for x = 0; x < template.width(); x = x + 1 {
      let left = source.get(origin_x + x, origin_y + y).to_int()
      let right = template.get(x, y).to_int()
      score = score + Int::abs(left - right)
    }
  }
  score
}

///|
pub fn match_template_sad(
  source : @image.GrayImage,
  template : @image.GrayImage,
) -> TemplateMatch raise @image.ImageError {
  if template.width() > source.width() || template.height() > source.height() {
    raise InvalidDimensions("template must not be larger than source image")
  }
  let mut best = { x: 0, y: 0, score: sad_at(source, template, 0, 0) }
  for y = 0; y <= source.height() - template.height(); y = y + 1 {
    for x = 0; x <= source.width() - template.width(); x = x + 1 {
      let score = sad_at(source, template, x, y)
      if score < best.score {
        best = { x, y, score }
      }
    }
  }
  best
}

///|
pub fn TemplateMatch::x(self : TemplateMatch) -> Int {
  self.x
}

///|
pub fn TemplateMatch::y(self : TemplateMatch) -> Int {
  self.y
}

///|
pub fn TemplateMatch::score(self : TemplateMatch) -> Int {
  self.score
}
