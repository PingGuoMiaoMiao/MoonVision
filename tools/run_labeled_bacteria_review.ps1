param(
  [string]$InputRoot = (Join-Path $env:USERPROFILE ("Desktop\" + [char]0x6253 + [char]0x6807)),
  [string]$OutputRoot = "C:\Users\chen\Desktop\MoonVision\examples\output\bacteria_labeled_review",
  [bool]$ExcludeSideViews = $true,
  [string[]]$SampleFolders = @(),
  [int]$MaxImages = 0,
  [switch]$ForceRerun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$runtimeDir = Join-Path $repoRoot "examples\runtime"
$probeInput = Join-Path $runtimeDir "bacteria_probe_input.png"
$probeCurrent = Join-Path $repoRoot "examples\output\bacteria_probe\current"
$probeExecutable = Join-Path $repoRoot "_build\native\release\build\demo\bacteria_probe\bacteria_probe.exe"
$bacteriaKeyword = ([string]([char]0x7EC6) + [char]0x83CC)
$minIou = 0.15

New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
New-Item -ItemType Directory -Force -Path $probeCurrent | Out-Null
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
& moon build --target native --release src/demo/bacteria_probe
if ($LASTEXITCODE -ne 0) {
  throw "moon build --target native --release src/demo/bacteria_probe failed"
}
if (-not (Test-Path -LiteralPath $probeExecutable)) {
  throw "probe executable not found at $probeExecutable"
}

function Get-RelativePath {
  param(
    [string]$BasePath,
    [string]$TargetPath
  )

  $baseFull = [System.IO.Path]::GetFullPath($BasePath)
  $targetFull = [System.IO.Path]::GetFullPath($TargetPath)
  if (-not $baseFull.EndsWith("\")) {
    $baseFull = $baseFull + "\"
  }
  $baseUri = New-Object System.Uri($baseFull)
  $targetUri = New-Object System.Uri($targetFull)
  $relativeUri = $baseUri.MakeRelativeUri($targetUri)
  [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Get-DeltaText {
  param(
    [int]$Delta
  )

  if ($Delta -eq 0) {
    return "match"
  }
  if ($Delta -gt 0) {
    return "over by $Delta"
  }
  return "under by $([math]::Abs($Delta))"
}

function Get-BoxWidth {
  param([object]$Box)
  return [double]$Box.Width
}

function Get-BoxHeight {
  param([object]$Box)
  return [double]$Box.Height
}

function Get-AnnotationBoxes {
  param([object]$Annotation)

  $boxes = @()
  $index = 0
  foreach ($shape in $Annotation.shapes) {
    if ($shape.shape_type -ne "rectangle") {
      continue
    }
    $x1 = [double]$shape.points[0][0]
    $y1 = [double]$shape.points[0][1]
    $x2 = [double]$shape.points[1][0]
    $y2 = [double]$shape.points[1][1]
    $left = [math]::Min($x1, $x2)
    $top = [math]::Min($y1, $y2)
    $width = [math]::Abs($x2 - $x1)
    $height = [math]::Abs($y2 - $y1)
    $boxes += [PSCustomObject]@{
      Id = $index
      Label = [string]$shape.label
      X = $left
      Y = $top
      Width = $width
      Height = $height
      Area = $width * $height
    }
    $index += 1
  }
  return $boxes
}

function Get-DetectedBoxes {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    return @()
  }
  $rows = Import-Csv -LiteralPath $Path
  $boxes = @()
  $index = 0
  foreach ($row in $rows) {
    $boxes += [PSCustomObject]@{
      Id = $index
      X = [double]$row.x
      Y = [double]$row.y
      Width = [double]$row.width
      Height = [double]$row.height
      Area = [double]$row.area
    }
    $index += 1
  }
  return $boxes
}

function Get-Iou {
  param(
    [object]$Left,
    [object]$Right
  )

  $leftX2 = $Left.X + $Left.Width
  $leftY2 = $Left.Y + $Left.Height
  $rightX2 = $Right.X + $Right.Width
  $rightY2 = $Right.Y + $Right.Height

  $ix1 = [math]::Max($Left.X, $Right.X)
  $iy1 = [math]::Max($Left.Y, $Right.Y)
  $ix2 = [math]::Min($leftX2, $rightX2)
  $iy2 = [math]::Min($leftY2, $rightY2)

  $iw = $ix2 - $ix1
  $ih = $iy2 - $iy1
  if ($iw -le 0 -or $ih -le 0) {
    return 0.0
  }

  $intersection = $iw * $ih
  $union = ($Left.Width * $Left.Height) + ($Right.Width * $Right.Height) - $intersection
  if ($union -le 0) {
    return 0.0
  }
  return $intersection / $union
}

function Match-Boxes {
  param(
    [object[]]$Annotations,
    [object[]]$Detections,
    [double]$MinIou
  )

  $candidates = @()
  foreach ($annotation in $Annotations) {
    foreach ($detection in $Detections) {
      $iou = Get-Iou -Left $annotation -Right $detection
      if ($iou -ge $MinIou) {
        $candidates += [PSCustomObject]@{
          AnnotationId = $annotation.Id
          DetectionId = $detection.Id
          IoU = $iou
        }
      }
    }
  }

  $matchedAnnotationIds = @{}
  $matchedDetectionIds = @{}
  $matches = @()
  foreach ($candidate in ($candidates | Sort-Object @{ Expression = 'IoU'; Descending = $true })) {
    if ($matchedAnnotationIds.ContainsKey($candidate.AnnotationId) -or $matchedDetectionIds.ContainsKey($candidate.DetectionId)) {
      continue
    }
    $matchedAnnotationIds[$candidate.AnnotationId] = $true
    $matchedDetectionIds[$candidate.DetectionId] = $true
    $matches += $candidate
  }

  $unmatchedAnnotations = @($Annotations | Where-Object { -not $matchedAnnotationIds.ContainsKey($_.Id) })
  $unmatchedDetections = @($Detections | Where-Object { -not $matchedDetectionIds.ContainsKey($_.Id) })
  $matchedCount = $matches.Count
  $detectedCount = $Detections.Count
  $labelCount = $Annotations.Count
  $falsePositiveCount = $unmatchedDetections.Count
  $falseNegativeCount = $unmatchedAnnotations.Count
  $precision = if ($detectedCount -gt 0) { $matchedCount / $detectedCount } else { 0.0 }
  $recall = if ($labelCount -gt 0) { $matchedCount / $labelCount } else { 0.0 }
  $f1 = if (($precision + $recall) -gt 0) { 2.0 * $precision * $recall / ($precision + $recall) } else { 0.0 }
  $meanIou = if ($matches.Count -gt 0) { ($matches | Measure-Object -Property IoU -Average).Average } else { 0.0 }

  return [PSCustomObject]@{
    Matches = $matches
    MatchedCount = $matchedCount
    FalsePositiveCount = $falsePositiveCount
    FalseNegativeCount = $falseNegativeCount
    Precision = $precision
    Recall = $recall
    F1 = $f1
    MeanIoU = $meanIou
    UnmatchedAnnotations = $unmatchedAnnotations
    UnmatchedDetections = $unmatchedDetections
  }
}

function New-LabelOverlaySvg {
  param(
    [object]$Annotation
  )

  $width = [int]$Annotation.imageWidth
  $height = [int]$Annotation.imageHeight
  $lines = @()
  $lines += "<svg xmlns=""http://www.w3.org/2000/svg"" width=""$width"" height=""$height"" viewBox=""0 0 $width $height"">"
  foreach ($shape in $Annotation.shapes) {
    if ($shape.shape_type -ne "rectangle") {
      continue
    }
    $x1 = [double]$shape.points[0][0]
    $y1 = [double]$shape.points[0][1]
    $x2 = [double]$shape.points[1][0]
    $y2 = [double]$shape.points[1][1]
    $left = [math]::Min($x1, $x2)
    $top = [math]::Min($y1, $y2)
    $rectWidth = [math]::Abs($x2 - $x1)
    $rectHeight = [math]::Abs($y2 - $y1)
    $label = [System.Security.SecurityElement]::Escape([string]$shape.label)
    $lines += "<rect x=""$left"" y=""$top"" width=""$rectWidth"" height=""$rectHeight"" fill=""none"" stroke=""#ff4d4f"" stroke-width=""4"" />"
    $lines += "<text x=""$left"" y=""$([math]::Max(20, $top - 8))"" fill=""#ff4d4f"" font-size=""24"" font-family=""Segoe UI, Arial, sans-serif"">$label</text>"
  }
  $lines += "</svg>"
  return ($lines -join "`n")
}

function New-AlignmentOverlaySvg {
  param(
    [int]$Width,
    [int]$Height,
    [object[]]$Annotations,
    [object[]]$Detections,
    [object]$MatchResult,
    [object]$Roi,
    [string]$BestParamSet
  )

  $matchedDetections = @{}
  foreach ($match in $MatchResult.Matches) {
    $matchedDetections[$match.DetectionId] = $true
  }

  $lines = @()
  $lines += "<svg xmlns=""http://www.w3.org/2000/svg"" width=""$Width"" height=""$Height"" viewBox=""0 0 $Width $Height"">"
  $lines += "<rect x=""$($Roi.x)"" y=""$($Roi.y)"" width=""$($Roi.width)"" height=""$($Roi.height)"" fill=""none"" stroke=""#2563eb"" stroke-width=""4"" />"
  $lines += "<text x=""20"" y=""36"" fill=""#111827"" font-size=""24"" font-family=""Segoe UI, Arial, sans-serif"">best=$BestParamSet matched=$($MatchResult.MatchedCount) fp=$($MatchResult.FalsePositiveCount) fn=$($MatchResult.FalseNegativeCount) iou&gt;=$minIou</text>"

  foreach ($annotation in $MatchResult.UnmatchedAnnotations) {
    $lines += "<rect x=""$($annotation.X)"" y=""$($annotation.Y)"" width=""$($annotation.Width)"" height=""$($annotation.Height)"" fill=""none"" stroke=""#f59e0b"" stroke-width=""5"" stroke-dasharray=""10 6"" />"
  }
  foreach ($detection in $Detections) {
    if ($matchedDetections.ContainsKey($detection.Id)) {
      $lines += "<rect x=""$($detection.X)"" y=""$($detection.Y)"" width=""$($detection.Width)"" height=""$($detection.Height)"" fill=""none"" stroke=""#16a34a"" stroke-width=""5"" />"
    } else {
      $lines += "<rect x=""$($detection.X)"" y=""$($detection.Y)"" width=""$($detection.Width)"" height=""$($detection.Height)"" fill=""none"" stroke=""#dc2626"" stroke-width=""5"" />"
    }
  }

  $lines += "</svg>"
  return ($lines -join "`n")
}

function New-ScatterPlotSvg {
  param(
    [object[]]$Items,
    [int]$Width = 560,
    [int]$Height = 380
  )

  $marginLeft = 56
  $marginBottom = 40
  $marginTop = 20
  $marginRight = 20
  $plotWidth = $Width - $marginLeft - $marginRight
  $plotHeight = $Height - $marginTop - $marginBottom
  $maxCount = [math]::Max(1, ($Items | ForEach-Object { [math]::Max($_.LabelCount, $_.BestDetectedCount) } | Measure-Object -Maximum).Maximum)

  $lines = @()
  $lines += "<svg xmlns=""http://www.w3.org/2000/svg"" width=""$Width"" height=""$Height"" viewBox=""0 0 $Width $Height"">"
  $lines += "<rect x=""0"" y=""0"" width=""$Width"" height=""$Height"" fill=""white"" />"
  $lines += "<line x1=""$marginLeft"" y1=""$marginTop"" x2=""$marginLeft"" y2=""$($marginTop + $plotHeight)"" stroke=""#94a3b8"" stroke-width=""2"" />"
  $lines += "<line x1=""$marginLeft"" y1=""$($marginTop + $plotHeight)"" x2=""$($marginLeft + $plotWidth)"" y2=""$($marginTop + $plotHeight)"" stroke=""#94a3b8"" stroke-width=""2"" />"
  $lines += "<line x1=""$marginLeft"" y1=""$($marginTop + $plotHeight)"" x2=""$($marginLeft + $plotWidth)"" y2=""$marginTop"" stroke=""#cbd5e1"" stroke-width=""2"" stroke-dasharray=""8 6"" />"
  $lines += "<text x=""$($Width / 2)"" y=""$($Height - 6)"" text-anchor=""middle"" fill=""#334155"" font-size=""14"">label count</text>"
  $lines += "<text x=""18"" y=""$($Height / 2)"" text-anchor=""middle"" fill=""#334155"" font-size=""14"" transform=""rotate(-90 18 $($Height / 2))"">best detected count</text>"

  for ($tick = 0; $tick -le $maxCount; $tick += [math]::Max(1, [math]::Ceiling($maxCount / 5))) {
    $x = $marginLeft + ($tick / $maxCount) * $plotWidth
    $y = $marginTop + $plotHeight - ($tick / $maxCount) * $plotHeight
    $lines += "<line x1=""$x"" y1=""$($marginTop + $plotHeight)"" x2=""$x"" y2=""$($marginTop + $plotHeight + 6)"" stroke=""#94a3b8"" stroke-width=""1"" />"
    $lines += "<line x1=""$($marginLeft - 6)"" y1=""$y"" x2=""$marginLeft"" y2=""$y"" stroke=""#94a3b8"" stroke-width=""1"" />"
    $lines += "<text x=""$x"" y=""$($marginTop + $plotHeight + 20)"" text-anchor=""middle"" fill=""#475569"" font-size=""12"">$tick</text>"
    $lines += "<text x=""$($marginLeft - 12)"" y=""$($y + 4)"" text-anchor=""end"" fill=""#475569"" font-size=""12"">$tick</text>"
  }

  foreach ($item in $Items) {
    $x = $marginLeft + ($item.LabelCount / $maxCount) * $plotWidth
    $y = $marginTop + $plotHeight - ($item.BestDetectedCount / $maxCount) * $plotHeight
    $lines += "<circle cx=""$x"" cy=""$y"" r=""5"" fill=""#2563eb"" />"
    $lines += "<text x=""$($x + 8)"" y=""$($y - 6)"" fill=""#0f172a"" font-size=""12"">$([System.Security.SecurityElement]::Escape($item.SampleFolder))</text>"
  }

  $lines += "</svg>"
  return ($lines -join "`n")
}

function Get-StBarWidth {
  param(
    [int]$Value,
    [int]$MaxValue
  )

  if ($MaxValue -le 0) {
    return 0
  }
  return [math]::Round($Value * 320.0 / $MaxValue, 1)
}

function Get-SummarySum {
  param(
    [object[]]$Items,
    [string]$PropertyName
  )

  if ($Items.Count -le 0) {
    return 0
  }
  $sum = ($Items | Measure-Object -Property $PropertyName -Sum).Sum
  if ($null -eq $sum) {
    return 0
  }
  return [int]$sum
}

function New-ModeSummaryItem {
  param(
    [string]$Mode,
    [object[]]$Items,
    [string]$MatchedProperty,
    [string]$FalsePositiveProperty,
    [string]$FalseNegativeProperty
  )

  $matched = Get-SummarySum -Items $Items -PropertyName $MatchedProperty
  $falsePositive = Get-SummarySum -Items $Items -PropertyName $FalsePositiveProperty
  $falseNegative = Get-SummarySum -Items $Items -PropertyName $FalseNegativeProperty
  $labels = $matched + $falseNegative
  $precision = if (($matched + $falsePositive) -gt 0) { [math]::Round($matched / ($matched + $falsePositive), 4) } else { 0.0 }
  $recall = if ($labels -gt 0) { [math]::Round($matched / $labels, 4) } else { 0.0 }
  $f1 = if (($precision + $recall) -gt 0) { [math]::Round(2.0 * $precision * $recall / ($precision + $recall), 4) } else { 0.0 }

  [PSCustomObject]@{
    Mode = $Mode
    Images = $Items.Count
    Labels = $labels
    Matched = $matched
    FalsePositive = $falsePositive
    FalseNegative = $falseNegative
    Precision = $precision
    Recall = $recall
    F1 = $f1
  }
}

$pairs = Get-ChildItem -File -Recurse $InputRoot |
  Where-Object { $_.FullName -like ("*" + $bacteriaKeyword + "*") -and $_.Extension -eq ".png" } |
  Where-Object {
    if (-not $ExcludeSideViews) {
      return $true
    }
    $parentLeaf = Split-Path -Leaf (Split-Path -Parent $_.FullName)
    return $parentLeaf -notlike "side*"
  } |
  ForEach-Object {
    $jsonPath = [System.IO.Path]::ChangeExtension($_.FullName, ".json")
    if (Test-Path $jsonPath) {
      [PSCustomObject]@{
        ImagePath = $_.FullName
        JsonPath = $jsonPath
      }
    }
  }

if ($SampleFolders.Count -gt 0) {
  $sampleFolderSet = @{}
  foreach ($sampleFolder in $SampleFolders) {
    $sampleFolderSet[[string]$sampleFolder] = $true
  }
  $pairs = @($pairs | Where-Object {
    $parentLeaf = Split-Path -Leaf (Split-Path -Parent $_.ImagePath)
    $sampleFolderSet.ContainsKey($parentLeaf)
  })
} else {
  $pairs = @($pairs)
}

if ($MaxImages -gt 0) {
  $pairs = @($pairs | Select-Object -First $MaxImages)
}

$summary = @()
$labelStats = @{}
$annotationOutcomes = @()

foreach ($pair in $pairs) {
  $annotation = Get-Content -Raw $pair.JsonPath | ConvertFrom-Json
  $annotationBoxes = @(Get-AnnotationBoxes -Annotation $annotation)
  $relativeImagePath = Get-RelativePath -BasePath $InputRoot -TargetPath $pair.ImagePath
  $relativeDir = Split-Path -Parent $relativeImagePath
  $leafName = [System.IO.Path]::GetFileNameWithoutExtension($pair.ImagePath)
  $safeRelativeDir = $relativeDir -replace '[\\/:*?"<>|]', '_'
  $itemDir = Join-Path $OutputRoot ($safeRelativeDir + "__" + $leafName)
  New-Item -ItemType Directory -Force -Path $itemDir | Out-Null
  $reuseExisting = (Test-Path (Join-Path $itemDir "preset_scores.csv")) -and
    ((Get-ChildItem -LiteralPath $itemDir -Filter "*_roi.csv" -ErrorAction SilentlyContinue).Count -gt 0) -and
    ((Get-ChildItem -LiteralPath $itemDir -Filter "*_boxes.csv" -ErrorAction SilentlyContinue).Count -gt 0)

  if ($ForceRerun -or (-not $reuseExisting)) {
    if (Test-Path $probeCurrent) {
      Get-ChildItem -LiteralPath $probeCurrent -Force | Remove-Item -Recurse -Force
    }
    if (Test-Path $itemDir) {
      Get-ChildItem -LiteralPath $itemDir -Force | Remove-Item -Recurse -Force
    }
    Copy-Item -LiteralPath $pair.ImagePath -Destination $probeInput -Force
    $runOutput = & $probeExecutable 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "probe executable failed for $($pair.ImagePath)`n$runOutput"
    }

    Copy-Item -LiteralPath $pair.ImagePath -Destination (Join-Path $itemDir "source.png") -Force
    Copy-Item -LiteralPath $pair.JsonPath -Destination (Join-Path $itemDir "annotation.json") -Force
    Get-ChildItem -LiteralPath $probeCurrent -Force | Copy-Item -Destination $itemDir -Recurse -Force
    Set-Content -LiteralPath (Join-Path $itemDir "annotation_boxes.svg") -Value (New-LabelOverlaySvg -Annotation $annotation) -Encoding UTF8
  }

  $presetScoreRows = @()
  foreach ($boxCsv in (Get-ChildItem -LiteralPath $itemDir -Filter "*_boxes.csv" | Sort-Object Name)) {
    $presetName = $boxCsv.BaseName -replace '_boxes$', ''
    $detectedBoxes = @(Get-DetectedBoxes -Path $boxCsv.FullName)
    $matchResult = Match-Boxes -Annotations $annotationBoxes -Detections $detectedBoxes -MinIou $minIou
    $detectedCount = $detectedBoxes.Count
    $countDelta = $detectedCount - $annotationBoxes.Count
    $presetScoreRows += [PSCustomObject]@{
      ParamSet = $presetName
      DetectedCount = $detectedCount
      CountDelta = $countDelta
      CountDeltaText = Get-DeltaText -Delta $countDelta
      MatchedCount = $matchResult.MatchedCount
      FalsePositiveCount = $matchResult.FalsePositiveCount
      FalseNegativeCount = $matchResult.FalseNegativeCount
      Precision = [math]::Round($matchResult.Precision, 4)
      Recall = [math]::Round($matchResult.Recall, 4)
      F1 = [math]::Round($matchResult.F1, 4)
      MeanIoU = [math]::Round($matchResult.MeanIoU, 4)
      RoiPath = (Join-Path $itemDir ($presetName + "_roi.csv"))
      MatchResult = $matchResult
      DetectedBoxes = $detectedBoxes
    }
  }

  $presetScoreRows |
    Select-Object ParamSet, DetectedCount, CountDelta, CountDeltaText, MatchedCount, FalsePositiveCount, FalseNegativeCount, Precision, Recall, F1, MeanIoU |
    Export-Csv -LiteralPath (Join-Path $itemDir "preset_scores.csv") -NoTypeInformation -Encoding UTF8

  $best = $presetScoreRows |
    Sort-Object `
      @{ Expression = 'F1'; Descending = $true }, `
      @{ Expression = 'MatchedCount'; Descending = $true }, `
      @{ Expression = 'FalsePositiveCount'; Descending = $false }, `
      @{ Expression = 'FalseNegativeCount'; Descending = $false }, `
      @{ Expression = { [math]::Abs($_.CountDelta) }; Descending = $false } |
    Select-Object -First 1

  $recallBest = $presetScoreRows |
    Sort-Object `
      @{ Expression = 'Recall'; Descending = $true }, `
      @{ Expression = 'MatchedCount'; Descending = $true }, `
      @{ Expression = 'FalseNegativeCount'; Descending = $false }, `
      @{ Expression = 'FalsePositiveCount'; Descending = $false }, `
      @{ Expression = 'F1'; Descending = $true } |
    Select-Object -First 1

  $precisionBest = $presetScoreRows |
    Where-Object { $_.DetectedCount -gt 0 } |
    Sort-Object `
      @{ Expression = 'Precision'; Descending = $true }, `
      @{ Expression = 'F1'; Descending = $true }, `
      @{ Expression = 'MatchedCount'; Descending = $true }, `
      @{ Expression = 'FalsePositiveCount'; Descending = $false }, `
      @{ Expression = 'FalseNegativeCount'; Descending = $false } |
    Select-Object -First 1
  if ($null -eq $precisionBest) {
    $precisionBest = $best
  }

  $bestAlignment = New-AlignmentOverlaySvg `
    -Width ([int]$annotation.imageWidth) `
    -Height ([int]$annotation.imageHeight) `
    -Annotations $annotationBoxes `
    -Detections $best.DetectedBoxes `
    -MatchResult $best.MatchResult `
    -Roi (Import-Csv -LiteralPath $best.RoiPath | Select-Object -First 1) `
    -BestParamSet $best.ParamSet
  Set-Content -LiteralPath (Join-Path $itemDir "best_alignment.svg") -Value $bestAlignment -Encoding UTF8

  $matchedAnnotationIds = @{}
  foreach ($match in $best.MatchResult.Matches) {
    $matchedAnnotationIds[[int]$match.AnnotationId] = $true
  }
  foreach ($annotationBox in $annotationBoxes) {
    $labelKey = [string]$annotationBox.Label
    if (-not $labelStats.ContainsKey($labelKey)) {
      $labelStats[$labelKey] = [PSCustomObject]@{
        Label = $labelKey
        TotalAnnotations = 0
        MatchedAnnotations = 0
        UnmatchedAnnotations = 0
        TotalArea = 0.0
        MatchedArea = 0.0
      }
    }
    $isMatched = $matchedAnnotationIds.ContainsKey([int]$annotationBox.Id)
    $stat = $labelStats[$labelKey]
    $stat.TotalAnnotations += 1
    $stat.TotalArea += [double]$annotationBox.Area
    if ($isMatched) {
      $stat.MatchedAnnotations += 1
      $stat.MatchedArea += [double]$annotationBox.Area
    } else {
      $stat.UnmatchedAnnotations += 1
    }
    $annotationOutcomes += [PSCustomObject]@{
      Label = $labelKey
      Area = [double]$annotationBox.Area
      Matched = $isMatched
    }
  }

  $batchFolder = ($relativeImagePath -split '\\')[0]
  $sampleFolder = Split-Path -Leaf (Split-Path -Parent $pair.ImagePath)
  $summary += [PSCustomObject]@{
    BatchFolder = $batchFolder
    SampleFolder = $sampleFolder
    RelativePath = $relativeImagePath
    LabelCount = $annotationBoxes.Count
    BestParamSet = $best.ParamSet
    BestDetectedCount = $best.DetectedCount
    BestCountDelta = $best.CountDelta
    BestCountDeltaText = $best.CountDeltaText
    MatchedCount = $best.MatchedCount
    FalsePositiveCount = $best.FalsePositiveCount
    FalseNegativeCount = $best.FalseNegativeCount
    Precision = $best.Precision
    Recall = $best.Recall
    F1 = $best.F1
    MeanIoU = $best.MeanIoU
    RecallParamSet = $recallBest.ParamSet
    RecallDetectedCount = $recallBest.DetectedCount
    RecallMatchedCount = $recallBest.MatchedCount
    RecallFalsePositiveCount = $recallBest.FalsePositiveCount
    RecallFalseNegativeCount = $recallBest.FalseNegativeCount
    RecallPrecision = $recallBest.Precision
    RecallRecall = $recallBest.Recall
    RecallF1 = $recallBest.F1
    PrecisionParamSet = $precisionBest.ParamSet
    PrecisionDetectedCount = $precisionBest.DetectedCount
    PrecisionMatchedCount = $precisionBest.MatchedCount
    PrecisionFalsePositiveCount = $precisionBest.FalsePositiveCount
    PrecisionFalseNegativeCount = $precisionBest.FalseNegativeCount
    PrecisionPrecision = $precisionBest.Precision
    PrecisionRecall = $precisionBest.Recall
    PrecisionF1 = $precisionBest.F1
    OutputFolder = $itemDir
  }
}

$summary |
  Export-Csv -LiteralPath (Join-Path $OutputRoot "summary.csv") -NoTypeInformation -Encoding UTF8

$summary |
  Select-Object BatchFolder, SampleFolder, RelativePath, LabelCount, BestParamSet, BestDetectedCount, BestCountDeltaText, MatchedCount, FalsePositiveCount, FalseNegativeCount, Precision, Recall, F1, MeanIoU, RecallParamSet, RecallDetectedCount, RecallMatchedCount, RecallFalsePositiveCount, RecallFalseNegativeCount, RecallPrecision, RecallRecall, RecallF1, PrecisionParamSet, PrecisionDetectedCount, PrecisionMatchedCount, PrecisionFalsePositiveCount, PrecisionFalseNegativeCount, PrecisionPrecision, PrecisionRecall, PrecisionF1 |
  Export-Csv -LiteralPath (Join-Path $OutputRoot "summary_readable.csv") -NoTypeInformation -Encoding UTF8

$labelSummary = $labelStats.GetEnumerator() |
  ForEach-Object {
    $value = $_.Value
    [PSCustomObject]@{
      Label = $value.Label
      TotalAnnotations = $value.TotalAnnotations
      MatchedAnnotations = $value.MatchedAnnotations
      UnmatchedAnnotations = $value.UnmatchedAnnotations
      Recall = if ($value.TotalAnnotations -gt 0) { [math]::Round($value.MatchedAnnotations / $value.TotalAnnotations, 4) } else { 0.0 }
      AverageArea = if ($value.TotalAnnotations -gt 0) { [math]::Round($value.TotalArea / $value.TotalAnnotations, 1) } else { 0.0 }
      MatchedAreaRatio = if ($value.TotalArea -gt 0) { [math]::Round($value.MatchedArea / $value.TotalArea, 4) } else { 0.0 }
    }
  } |
  Sort-Object Label

$labelSummary |
  Export-Csv -LiteralPath (Join-Path $OutputRoot "label_summary.csv") -NoTypeInformation -Encoding UTF8

$sortedAreas = @($annotationOutcomes | ForEach-Object { [double]$_.Area } | Sort-Object)
$sizeSummary = @()
if ($sortedAreas.Count -gt 0) {
  $smallUpper = $sortedAreas[[int][math]::Floor(($sortedAreas.Count - 1) / 3)]
  $mediumUpper = $sortedAreas[[int][math]::Floor((($sortedAreas.Count - 1) * 2) / 3)]
  $sizeBuckets = @(
    [PSCustomObject]@{ Name = "small"; Min = 0.0; Max = $smallUpper },
    [PSCustomObject]@{ Name = "medium"; Min = $smallUpper + 0.0001; Max = $mediumUpper },
    [PSCustomObject]@{ Name = "large"; Min = $mediumUpper + 0.0001; Max = [double]::PositiveInfinity }
  )
  foreach ($bucket in $sizeBuckets) {
    $bucketRows = @($annotationOutcomes | Where-Object {
      if ([double]::IsPositiveInfinity($bucket.Max)) {
        [double]$_.Area -ge $bucket.Min
      } else {
        [double]$_.Area -ge $bucket.Min -and [double]$_.Area -le $bucket.Max
      }
    })
    $total = $bucketRows.Count
    $matched = @($bucketRows | Where-Object { $_.Matched }).Count
    $sizeSummary += [PSCustomObject]@{
      SizeBucket = $bucket.Name
      AreaMin = [math]::Round($bucket.Min, 1)
      AreaMax = if ([double]::IsPositiveInfinity($bucket.Max)) { "Infinity" } else { [math]::Round($bucket.Max, 1).ToString() }
      TotalAnnotations = $total
      MatchedAnnotations = $matched
      UnmatchedAnnotations = $total - $matched
      Recall = if ($total -gt 0) { [math]::Round($matched / $total, 4) } else { 0.0 }
    }
  }
}

$sizeSummary |
  Export-Csv -LiteralPath (Join-Path $OutputRoot "size_summary.csv") -NoTypeInformation -Encoding UTF8

$imageCount = $summary.Count
$modeSummary = @(
  New-ModeSummaryItem `
    -Mode "F1-oriented" `
    -Items $summary `
    -MatchedProperty "MatchedCount" `
    -FalsePositiveProperty "FalsePositiveCount" `
    -FalseNegativeProperty "FalseNegativeCount"
  New-ModeSummaryItem `
    -Mode "Recall-oriented" `
    -Items $summary `
    -MatchedProperty "RecallMatchedCount" `
    -FalsePositiveProperty "RecallFalsePositiveCount" `
    -FalseNegativeProperty "RecallFalseNegativeCount"
  New-ModeSummaryItem `
    -Mode "Precision-oriented" `
    -Items $summary `
    -MatchedProperty "PrecisionMatchedCount" `
    -FalsePositiveProperty "PrecisionFalsePositiveCount" `
    -FalseNegativeProperty "PrecisionFalseNegativeCount"
)

$modeSummary |
  Export-Csv -LiteralPath (Join-Path $OutputRoot "mode_summary.csv") -NoTypeInformation -Encoding UTF8

$avgMatched = if ($imageCount -gt 0) { [math]::Round((($summary | Measure-Object -Property MatchedCount -Average).Average), 2) } else { 0 }
$avgFp = if ($imageCount -gt 0) { [math]::Round((($summary | Measure-Object -Property FalsePositiveCount -Average).Average), 2) } else { 0 }
$avgFn = if ($imageCount -gt 0) { [math]::Round((($summary | Measure-Object -Property FalseNegativeCount -Average).Average), 2) } else { 0 }
$avgF1 = if ($imageCount -gt 0) { [math]::Round((($summary | Measure-Object -Property F1 -Average).Average), 3) } else { 0 }
$avgIou = if ($imageCount -gt 0) { [math]::Round((($summary | Measure-Object -Property MeanIoU -Average).Average), 3) } else { 0 }
$maxStack = [math]::Max(1, ($summary | ForEach-Object { $_.MatchedCount + $_.FalsePositiveCount + $_.FalseNegativeCount } | Measure-Object -Maximum).Maximum)
$paramWins = $summary | Group-Object BestParamSet | Sort-Object Count -Descending
$paramWinText = ($paramWins | ForEach-Object { $_.Name + " " + $_.Count }) -join " / "

$stackedRows = foreach ($item in $summary) {
  $matchedWidth = Get-StBarWidth -Value $item.MatchedCount -MaxValue $maxStack
  $fpWidth = Get-StBarWidth -Value $item.FalsePositiveCount -MaxValue $maxStack
  $fnWidth = Get-StBarWidth -Value $item.FalseNegativeCount -MaxValue $maxStack
  @"
<div class="chart-row">
  <div class="chart-label">$([System.Security.SecurityElement]::Escape($item.SampleFolder))</div>
  <div class="chart-bars">
    <div class="stack-line">
      <span class="stack matched" style="width:${matchedWidth}px"></span>
      <span class="stack fp" style="width:${fpWidth}px"></span>
      <span class="stack fn" style="width:${fnWidth}px"></span>
      <span class="stack-value">matched=$($item.MatchedCount) fp=$($item.FalsePositiveCount) fn=$($item.FalseNegativeCount)</span>
    </div>
  </div>
</div>
"@
}

$rows = foreach ($item in $summary) {
  $reportPath = (Get-RelativePath -BasePath $OutputRoot -TargetPath (Join-Path $item.OutputFolder "report.html")).Replace('\', '/')
  $sourcePath = (Get-RelativePath -BasePath $OutputRoot -TargetPath (Join-Path $item.OutputFolder "source.png")).Replace('\', '/')
  $annotationPath = (Get-RelativePath -BasePath $OutputRoot -TargetPath (Join-Path $item.OutputFolder "annotation_boxes.svg")).Replace('\', '/')
  $alignmentPath = (Get-RelativePath -BasePath $OutputRoot -TargetPath (Join-Path $item.OutputFolder "best_alignment.svg")).Replace('\', '/')
  $scoresPath = (Get-RelativePath -BasePath $OutputRoot -TargetPath (Join-Path $item.OutputFolder "preset_scores.csv")).Replace('\', '/')
  "<tr><td>$([System.Security.SecurityElement]::Escape($item.BatchFolder))</td><td>$([System.Security.SecurityElement]::Escape($item.SampleFolder))</td><td>$([System.Security.SecurityElement]::Escape($item.RelativePath))</td><td>$($item.LabelCount)</td><td>$($item.BestParamSet)</td><td>$($item.BestDetectedCount)</td><td>$($item.BestCountDeltaText)</td><td>$($item.MatchedCount)</td><td>$($item.FalsePositiveCount)</td><td>$($item.FalseNegativeCount)</td><td>$($item.Precision)</td><td>$($item.Recall)</td><td>$($item.F1)</td><td>$($item.MeanIoU)</td><td>$($item.RecallParamSet)</td><td>$($item.RecallMatchedCount)</td><td>$($item.RecallFalsePositiveCount)</td><td>$($item.RecallFalseNegativeCount)</td><td>$($item.RecallRecall)</td><td>$($item.PrecisionParamSet)</td><td>$($item.PrecisionMatchedCount)</td><td>$($item.PrecisionFalsePositiveCount)</td><td>$($item.PrecisionFalseNegativeCount)</td><td>$($item.PrecisionPrecision)</td><td><a href=""$sourcePath"">source</a></td><td><a href=""$annotationPath"">labels</a></td><td><a href=""$alignmentPath"">best alignment</a></td><td><a href=""$scoresPath"">preset scores</a></td><td><a href=""$reportPath"">probe report</a></td></tr>"
}

$scatterSvg = New-ScatterPlotSvg -Items $summary
$labelRows = foreach ($item in $labelSummary) {
  "<tr><td>$([System.Security.SecurityElement]::Escape($item.Label))</td><td>$($item.TotalAnnotations)</td><td>$($item.MatchedAnnotations)</td><td>$($item.UnmatchedAnnotations)</td><td>$($item.Recall)</td><td>$($item.AverageArea)</td><td>$($item.MatchedAreaRatio)</td></tr>"
}
$sizeRows = foreach ($item in $sizeSummary) {
  "<tr><td>$([System.Security.SecurityElement]::Escape($item.SizeBucket))</td><td>$($item.AreaMin)</td><td>$($item.AreaMax)</td><td>$($item.TotalAnnotations)</td><td>$($item.MatchedAnnotations)</td><td>$($item.UnmatchedAnnotations)</td><td>$($item.Recall)</td></tr>"
}
$modeRows = foreach ($item in $modeSummary) {
  "<tr><td>$([System.Security.SecurityElement]::Escape($item.Mode))</td><td>$($item.Images)</td><td>$($item.Labels)</td><td>$($item.Matched)</td><td>$($item.FalsePositive)</td><td>$($item.FalseNegative)</td><td>$($item.Precision)</td><td>$($item.Recall)</td><td>$($item.F1)</td></tr>"
}

$index = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>MoonVision Bacteria Labeled Review</title>
  <style>
    body { font-family: "Segoe UI", Arial, sans-serif; margin: 24px; color: #1f2328; background: #ffffff; }
    h1, h2 { margin-bottom: 10px; }
    .note { color: #57606a; margin-top: 0; }
    .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin: 20px 0; }
    .card { border: 1px solid #d0d7de; border-radius: 10px; padding: 14px; background: #f6f8fa; }
    .card .label { font-size: 12px; color: #57606a; text-transform: uppercase; }
    .card .value { font-size: 28px; font-weight: 700; margin-top: 6px; }
    .section { margin: 28px 0; }
    .chart-grid { display: grid; gap: 10px; }
    .chart-row { display: grid; grid-template-columns: 80px 1fr; gap: 12px; align-items: start; }
    .chart-label { font-weight: 600; padding-top: 4px; }
    .chart-bars { display: grid; gap: 6px; }
    .stack-line { display: grid; grid-template-columns: auto auto auto 1fr; gap: 0; align-items: center; }
    .stack { height: 14px; display: inline-block; }
    .stack.matched { background: #16a34a; }
    .stack.fp { background: #dc2626; }
    .stack.fn { background: #f59e0b; }
    .stack-value { padding-left: 10px; font-variant-numeric: tabular-nums; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #d0d7de; padding: 8px 10px; text-align: left; vertical-align: top; }
    th { background: #f6f8fa; position: sticky; top: 0; }
    tr:nth-child(even) { background: #fbfbfb; }
    .legend { display: flex; gap: 16px; flex-wrap: wrap; font-size: 12px; color: #57606a; margin-bottom: 10px; }
    .legend span::before { content: ""; display: inline-block; width: 12px; height: 12px; border-radius: 999px; margin-right: 6px; vertical-align: -1px; }
    .legend .matched::before { background: #16a34a; }
    .legend .fp::before { background: #dc2626; }
    .legend .fn::before { background: #f59e0b; }
    .plot { border: 1px solid #d0d7de; border-radius: 10px; background: #ffffff; padding: 8px; display: inline-block; }
  </style>
</head>
<body>
  <h1>MoonVision Bacteria Labeled Review</h1>
  <p class="note">Input root: $([System.Security.SecurityElement]::Escape($InputRoot))</p>
  <p class="note">IoU match threshold: $minIou | Readable CSV: <a href="summary_readable.csv">summary_readable.csv</a> | Raw CSV: <a href="summary.csv">summary.csv</a> | Mode CSV: <a href="mode_summary.csv">mode_summary.csv</a> | Label CSV: <a href="label_summary.csv">label_summary.csv</a> | Size CSV: <a href="size_summary.csv">size_summary.csv</a></p>

  <div class="cards">
    <div class="card"><div class="label">Images</div><div class="value">$imageCount</div></div>
    <div class="card"><div class="label">Avg Matched</div><div class="value">$avgMatched</div></div>
    <div class="card"><div class="label">Avg False Positive</div><div class="value">$avgFp</div></div>
    <div class="card"><div class="label">Avg False Negative</div><div class="value">$avgFn</div></div>
    <div class="card"><div class="label">Avg F1</div><div class="value">$avgF1</div></div>
    <div class="card"><div class="label">Avg Mean IoU</div><div class="value">$avgIou</div></div>
    <div class="card"><div class="label">Best Param Wins</div><div class="value">$([System.Security.SecurityElement]::Escape($paramWinText))</div></div>
  </div>

  <div class="section">
    <h2>Label Count vs Best Detected Count</h2>
    <p class="note">Points closer to the diagonal are better. This is the most direct count-level overview after parameter selection.</p>
    <div class="plot">
      $scatterSvg
    </div>
  </div>

  <div class="section">
    <h2>Review Mode Summary</h2>
    <p class="note">F1-oriented is the default view. Recall-oriented keeps the highest-recall route visible, while precision-oriented shows the lowest-noise route for each image.</p>
  </div>
  <table>
    <thead>
      <tr>
        <th>Mode</th>
        <th>Images</th>
        <th>Labels</th>
        <th>Matched</th>
        <th>False Positive</th>
        <th>False Negative</th>
        <th>Precision</th>
        <th>Recall</th>
        <th>F1</th>
      </tr>
    </thead>
    <tbody>
      $($modeRows -join "`n      ")
    </tbody>
  </table>

  <div class="section">
    <h2>Matched / False Positive / False Negative</h2>
    <p class="note">Each row shows the best parameter set for that image. Green is matched, red is false positive, yellow is false negative.</p>
    <div class="legend"><span class="matched">matched</span><span class="fp">false positive</span><span class="fn">false negative</span></div>
    <div class="chart-grid">
      $($stackedRows -join "`n      ")
    </div>
  </div>

  <div class="section">
    <h2>Best-Result Coverage by Label</h2>
    <p class="note">This table uses the exact label strings from the annotation JSON and aggregates whether each annotation was matched under the best parameter set of each image.</p>
  </div>
  <table>
    <thead>
      <tr>
        <th>Label</th>
        <th>Total Annotations</th>
        <th>Matched Annotations</th>
        <th>Unmatched Annotations</th>
        <th>Recall</th>
        <th>Average Area</th>
        <th>Matched Area Ratio</th>
      </tr>
    </thead>
    <tbody>
      $($labelRows -join "`n      ")
    </tbody>
  </table>

  <div class="section">
    <h2>Best-Result Coverage by Size Bucket</h2>
    <p class="note">Size buckets are derived from the current annotation area distribution, split into three ordered ranges.</p>
  </div>
  <table>
    <thead>
      <tr>
        <th>Size Bucket</th>
        <th>Area Min</th>
        <th>Area Max</th>
        <th>Total Annotations</th>
        <th>Matched Annotations</th>
        <th>Unmatched Annotations</th>
        <th>Recall</th>
      </tr>
    </thead>
    <tbody>
      $($sizeRows -join "`n      ")
    </tbody>
  </table>

  <div class="section">
    <h2>Per-Image Detail</h2>
    <p class="note">`Best Count Result` compares best detected count to label count. `preset scores` contains every parameter set for that image.</p>
  </div>
  <table>
    <thead>
      <tr>
        <th>Batch</th>
        <th>Sample</th>
        <th>Image</th>
        <th>Label Count</th>
        <th>Best Param Set</th>
        <th>Best Detected Count</th>
        <th>Best Count Result</th>
        <th>Matched</th>
        <th>False Positive</th>
        <th>False Negative</th>
        <th>Precision</th>
        <th>Recall</th>
        <th>F1</th>
        <th>Mean IoU</th>
        <th>Recall Param Set</th>
        <th>Recall Matched</th>
        <th>Recall False Positive</th>
        <th>Recall False Negative</th>
        <th>Recall Score</th>
        <th>Precision Param Set</th>
        <th>Precision Matched</th>
        <th>Precision False Positive</th>
        <th>Precision False Negative</th>
        <th>Precision Score</th>
        <th>Source</th>
        <th>Label Overlay</th>
        <th>Best Alignment</th>
        <th>Preset Scores</th>
        <th>Probe Report</th>
      </tr>
    </thead>
    <tbody>
      $($rows -join "`n      ")
    </tbody>
  </table>
</body>
</html>
"@

Set-Content -LiteralPath (Join-Path $OutputRoot "index.html") -Value $index -Encoding UTF8
Write-Output "output_root=$OutputRoot"
