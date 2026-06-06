fn test_component() -> @components.Component {
  let img = try! @image.gray_from_array(
    6,
    5,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\x00',
      b'\x00',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\x00',
      b'\x00',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\xff',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
  let components = try! @components.connected_components(img)
  components[0]
}

///|
test "svg overlay renders bounding boxes" {
  inspect(
    svg_bounding_boxes(12, 8, [test_component()]),
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 8" width="12" height="8">
      #|  <title>MoonVision Detection Overlay</title>
      #|  <rect x="2" y="1" width="4" height="3" fill="none" stroke="#ff3b30" stroke-width="1" />
      #|  <text x="2" y="0" fill="#ff3b30" font-size="4">id=1 area=12</text>
      #|</svg>
    ),
  )
}

///|
test "html report renders summary and gallery" {
  inspect(
    html_report(
      "Object Counting Demo",
      ["detected objects: 4", "minimum area: 2"],
      [report_image("binary output", "binary.png")],
    ),
    content=(
      #|<!doctype html>
      #|<html lang="en">
      #|<head>
      #|  <meta charset="utf-8" />
      #|  <meta name="viewport" content="width=device-width, initial-scale=1" />
      #|  <title>Object Counting Demo</title>
      #|  <style>
      #|    body { font-family: "Segoe UI", sans-serif; margin: 24px; color: #1f2933; background: #f7fafc; }
      #|    h1 { margin-bottom: 12px; }
      #|    ul { padding-left: 20px; }
      #|    .gallery { display: grid; gap: 16px; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); }
      #|    figure { background: white; padding: 12px; border: 1px solid #d9e2ec; border-radius: 8px; }
      #|    img { max-width: 100%; height: auto; display: block; background: #eef2f7; }
      #|    figcaption { margin-bottom: 8px; font-weight: 600; }
      #|  </style>
      #|</head>
      #|<body>
      #|  <h1>Object Counting Demo</h1>
      #|  <ul>
      #|    <li>detected objects: 4</li>
      #|    <li>minimum area: 2</li>
      #|  </ul>
      #|  <div class="gallery">
      #|    <figure>
      #|      <figcaption>binary output</figcaption>
      #|      <img src="binary.png" alt="binary output" />
      #|    </figure>
      #|  </div>
      #|</body>
      #|</html>
    ),
  )
}

///|
test "png encoding writes a valid signature" {
  let img = try! @image.gray_from_array(1, 1, [b'\xff'])
  let png = encode_gray_png(img)
  inspect(png[0].to_int(), content="137")
  inspect(png[1].to_int(), content="80")
  inspect(png[2].to_int(), content="78")
  inspect(png[3].to_int(), content="71")
}
