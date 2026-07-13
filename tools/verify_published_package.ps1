param(
  [string]$PackageName = "PingGuoMiaoMiao/MoonVision"
)

$ErrorActionPreference = "Stop"

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("moonvision-published-" + [System.Guid]::NewGuid().ToString("N"))
$src = Join-Path $root "src"
$main = Join-Path $src "main"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

New-Item -ItemType Directory -Path $main | Out-Null

[System.IO.File]::WriteAllText((Join-Path $root "moon.mod.json"), @"
{
  "name": "PingGuoMiaoMiao/MoonVisionSmoke",
  "version": "0.1.0",
  "source": "src"
}
"@, $utf8NoBom)

Push-Location $root
try {
  moon add $PackageName

[System.IO.File]::WriteAllText((Join-Path $main "moon.pkg.json"), @"
{
  "is-main": true,
  "import": [
    {
      "path": "PingGuoMiaoMiao/MoonVision/image",
      "alias": "image"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/ops",
      "alias": "ops"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/filter",
      "alias": "filter"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/edge",
      "alias": "edge"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/morphology",
      "alias": "morphology"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/components",
      "alias": "components"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/histogram",
      "alias": "histogram"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/match",
      "alias": "match"
    },
    {
      "path": "PingGuoMiaoMiao/MoonVision/export",
      "alias": "export"
    }
  ]
}
"@, $utf8NoBom)

[System.IO.File]::WriteAllText((Join-Path $main "main.mbt"), @'
fn main {
  let gray = try! @image.gray_from_array(
    4,
    4,
    [
      b'\x00', b'\x00', b'\xff', b'\xff',
      b'\x00', b'\x40', b'\xc0', b'\xff',
      b'\x00', b'\x40', b'\xc0', b'\xff',
      b'\x00', b'\x00', b'\xff', b'\xff',
    ],
  )
  let binary = try! @ops.threshold(gray, 100)
  let blurred = try! @filter.gaussian_blur(gray, radius=1)
  let edges = try! @edge.canny_edges(blurred, 32, 96)
  let closed = try! @morphology.close_binary(binary, radius=1)
  let blobs = try! @components.connected_components(closed, min_area=1)
  let contours = try! @components.find_contours(closed)
  let equalized = try! @histogram.equalize_histogram(gray)
  let matched = try! @match.match_template_sad(gray, gray)
  let png = @export.encode_gray_png(edges)
  println(
    "moonvision-published-ok width=\{gray.width()}, height=\{gray.height()}, blobs=\{blobs.length()}, contours=\{contours.length()}, match_score=\{matched.score()}, png_bytes=\{png.length()}, equalized_pixels=\{equalized.pixel_count()}"
  )
}
'@, $utf8NoBom)

  moon check
  moon run src/main
} finally {
  Pop-Location
  Remove-Item -LiteralPath $root -Recurse -Force
}
