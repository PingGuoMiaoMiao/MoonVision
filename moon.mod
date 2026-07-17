name = "PingGuoMiaoMiao/MoonVision"

version = "0.2.4"

readme = "README.md"

repository = "https://github.com/PingGuoMiaoMiao/MoonVision"

license = "MIT"

keywords = [ "moonbit", "image-processing", "computer-vision" ]

description = "MoonBit-native lightweight image processing and basic computer vision algorithms."

source = "src"

preferred_target = "native"

options(
  exclude: [
    "_build",
    "target",
    ".mooncakes",
    ".obsidian",
    ".vscode",
    ".github",
    "examples/output/*",
    "examples/runtime/*",
    "src/**/pkg.generated.mbti",
  ],
)
