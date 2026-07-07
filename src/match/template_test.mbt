///|
test "sad template matching finds exact embedded template" {
  let source = try! @image.gray_from_array(4, 4, [
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x10', b'\x20', b'\x00', b'\x00',
    b'\x30', b'\x40', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  let template = try! @image.gray_from_array(2, 2, [
    b'\x10', b'\x20', b'\x30', b'\x40',
  ])
  let found = try! match_template_sad(source, template)
  inspect(found.x(), content="1")
  inspect(found.y(), content="1")
  inspect(found.score(), content="0")
}

///|
test "sad template matching rejects oversized templates" {
  let source = try! @image.gray(2, 2)
  let template = try! @image.gray(3, 2)
  let err = try? match_template_sad(source, template)
  inspect(
    match err {
      Err(@image.InvalidDimensions(message)) =>
        message == "template must not be larger than source image"
      _ => false
    },
    content="true",
  )
}

///|
test "sad template matching keeps first location for equal scores" {
  let source = try! @image.gray(3, 3, fill=b'\x20')
  let template = try! @image.gray(2, 2, fill=b'\x20')
  let found = try! match_template_sad(source, template)
  inspect(found.x(), content="0")
  inspect(found.y(), content="0")
  inspect(found.score(), content="0")
}

///|
test "sad score improves for closer image region" {
  let source = try! @image.gray_from_array(3, 1, [b'\x00', b'\x10', b'\x40'])
  let close = try! @image.gray_from_array(1, 1, [b'\x12'])
  let far = try! @image.gray_from_array(1, 1, [b'\x7f'])
  let close_match = try! match_template_sad(source, close)
  let far_match = try! match_template_sad(source, far)
  inspect(close_match.score() < far_match.score(), content="true")
}
