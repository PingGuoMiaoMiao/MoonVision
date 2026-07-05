# MoonVision：轻量级图像处理与基础计算机视觉算法库

## 基本信息

- **项目名称**：MoonVision：轻量级图像处理与基础计算机视觉算法库
- **参赛者**：苹果喵喵
- **联系方式**：15920836869
- **GitHub 仓库链接**：https://github.com/PingGuoMiaoMiao/MoonVision
- **项目方向**：MoonBit 图像处理 / 计算机视觉基础库
- **是否为移植项目**：否（原创 MoonBit-native 实现）

---

## 项目简介

MoonVision 是一个 MoonBit-native 的轻量级图像处理与基础计算机视觉算法库，旨在为 MoonBit 生态提供可复用的图像处理功能和基础视觉算法能力。

项目面向以下使用场景：

- 需要图像处理能力的应用开发者，例如文档增强、图像分析、数据可视化；
- 工具开发者，例如 CLI 图像工具、图像处理 pipeline 和教学 demo 工具；
- 教学与可视化展示场景，用于帮助开发者理解基础图像处理和计算机视觉算法。

MoonVision 聚焦算法层能力，计划提供从基础图像矩阵操作到边缘检测、滤波、形态学处理和连通域分析的一组核心功能，并通过复用 MoonBit 生态现有图像编解码能力实现结果导出与可视化展示。

---

## 核心功能范围

- **图像矩阵操作**：提供 `GrayImage`、`RgbImage` 等基础图像结构，支持尺寸信息、像素访问和像素修改；
- **基础图像处理**：支持灰度化、二值化、反转、亮度调整和对比度调整；
- **卷积与邻域滤波**：支持 Box Blur、Gaussian Blur、Sharpen、Median Blur 等常见滤波操作；
- **边缘检测**：支持 Sobel X/Y、梯度幅值计算、基础边缘提取和 Canny 边缘检测；
- **形态学操作**：支持 Erosion、Dilation、Opening、Closing；
- **连通域与轮廓分析**：支持 Connected Components、Contours、Contour Hierarchy，并提供 Bounding Boxes、面积过滤、轮廓统计、形状描述和目标计数；
- **基础几何变换**：支持灰度图缩放、水平翻转、垂直翻转和 90 度旋转；
- **可视化输出**：支持将处理结果导出为 PNG、SVG 或 HTML 报告；
- **Demo 示例**：
  - 物体计数，例如圆点、硬币、方块、细胞等目标计数；
  - 边缘检测，将输入图像转换为轮廓图；
  - 文档扫描增强，包括黑白化、去噪和基础增强处理；
  - 标注图像复核，例如针对本地标注数据生成检测框、统计报表和 HTML 可视化报告。

---

## 移植或参考说明

- **原项目**：本项目为原创 MoonBit-native 实现。
- **参考资料**：参考 OpenCV 图像处理文档、常见计算机视觉算法实现和基础图像处理教材。
- **实现方式**：本项目使用 MoonBit 原生模块、包结构、类型系统和测试方式组织代码。
- **依赖说明**：本项目不依赖 OpenCV 或其他 C/C++ 图像处理库；图像编解码部分计划复用 MoonBit 生态中已有的图像读写能力，例如 `mizchi/image`。MoonVision 专注于图像处理算法层，而不是重复实现图像编解码功能。

---

## 项目设计亮点

1. **轻量、可控、可复用**  
   项目聚焦基础图像处理与基础视觉算法，功能范围清晰，适合在中等规模 MoonBit 代码量内完成并维护。

2. **算法层专注**  
   MoonVision 不做 OpenCV 绑定，不重复实现图片编解码，也不做像素级 diff 工具，而是专注于灰度化、滤波、边缘检测、形态学和连通域分析等算法能力。

3. **直观演示效果**  
   项目提供边缘检测、物体计数、文档增强等 demo，并通过 SVG / HTML / PNG 输出可视化结果，方便评审和用户直观看到处理效果。

4. **生态补位价值**  
   当前 MoonBit 生态已有图像编解码和像素比较相关工具，但缺少一个 MoonBit-native 的轻量级图像处理与基础计算机视觉算法库。MoonVision 可以作为这些底层图像库之上的算法层补充。

5. **教育价值**  
   项目实现的算法清晰、可测试、结果可视化明显，可作为 MoonBit 图像处理和计算机视觉教学示例。

---

## 版本规划

- **v1.0：基础视觉分析阶段**  
  聚焦图像矩阵、基础图像处理、卷积滤波、Sobel 边缘检测、形态学处理、连通域分析以及 PNG / SVG / HTML 可视化输出，形成可用于物体计数、边缘检测与文档增强的第一条完整处理链路。

- **v1.1：稳健性与增强阶段**  
  在基础视觉分析链路之上，继续补充自动阈值、局部阈值、非线性去噪与基础几何变换能力，提升不同光照条件下的稳定性与图像预处理质量。

- **v1.2：边缘与轮廓扩展阶段**  
  进一步扩展 Canny 边缘检测、轮廓提取、轮廓统计等能力，使项目从基础视觉分析能力向更完整的轻量级 `imgproc` 算法层推进。

- **v1.3：轮廓层级与结构化分析阶段**  
  继续完善轮廓语义，支持外轮廓、孔洞轮廓和层级关系表达，使轮廓结果能够服务于更复杂的区域分析与可视化展示。

- **v1.4：形状分析与描述子阶段**  
  在轮廓基础上补充近似多边形、凸包、旋转外接矩形、圆度、实心度等轻量级形状分析能力，提升 MoonVision 在基础目标分析场景中的表达能力。

- **v1.5：标注复核与最终展示阶段**  
  面向比赛评审与实际样例展示，补充标注数据批量复核、检测参数评分、F1 / Recall / Precision 多口径报告、标签统计、尺寸分桶统计和 HTML 报告输出，使算法库具备更完整的演示与验证闭环。

- **v2.0：轻量级 imgproc 扩展阶段**  
  继续补充轮廓分析增强、几何矫正、直方图增强等能力，逐步形成面向 MoonBit 生态的轻量级图像处理与基础计算机视觉算法库。

---

## 目录结构示例

```text
moonvision/
  moon.mod.json
  README.md
  LICENSE

  src/
    image/
      moon.pkg.json
      gray.mbt
      rgb.mbt
      codec.mbt
      transform.mbt

    ops/
      moon.pkg.json
      grayscale.mbt
      threshold.mbt
      otsu.mbt
      adaptive_threshold.mbt
      invert.mbt
      brightness.mbt
      contrast.mbt
      ops_test.mbt

    filter/
      moon.pkg.json
      convolution.mbt
      box.mbt
      gaussian.mbt
      median.mbt
      sharpen.mbt
      filter_test.mbt

    edge/
      moon.pkg.json
      sobel.mbt
      canny.mbt
      edge_test.mbt

    morphology/
      moon.pkg.json
      binary.mbt
      morphology_test.mbt

    components/
      moon.pkg.json
      connected_components.mbt
      contours.mbt
      components_test.mbt

    export/
      moon.pkg.json
      png.mbt
      report.mbt

    demo/
      object_counting/
        moon.pkg.json
        main.mbt
      edge_detection/
        moon.pkg.json
        main.mbt
      document_enhancement/
        moon.pkg.json
        main.mbt
      bacteria_probe/
        moon.pkg.json
        main.mbt

  tools/
    run_labeled_bacteria_review.ps1

  examples/
    assets/
    output/
```

说明：

- 各功能目录按 MoonBit 包组织；
- 测试文件就近放在对应功能包内，便于维护与运行；
- `examples/assets` 存放 demo 输入样例，`examples/output` 存放生成结果。

---

## Demo / 展示示例

### 1. 物体计数

输入图片 `coins.png`，经过以下处理流程：

```text
灰度化 -> 阈值化 -> 形态学去噪 -> 连通域分析 -> Bounding Box 绘制
```

输出带框 SVG 和 HTML 报告。

示例输出：

```text
detected objects: 37
bounding boxes: [...coordinates...]
```

该 demo 可用于展示 MoonVision 在简单目标计数、工业检测、细胞计数、硬币计数等场景中的基础能力。

---

### 2. 边缘检测

输入图片 `input.png`，经过以下处理流程：

```text
灰度化 -> 高斯模糊 -> Sobel X/Y -> 梯度幅值 -> 阈值化
```

输出 `edges.png`。

效果说明：

> 原图会被转换为轮廓图，直观展示边缘检测效果。

---

### 3. 文档增强

输入拍照文档，经过以下处理流程：

```text
灰度化 -> 阈值化 -> 去噪 -> 输出黑白文档图片
```

用途：

> 可用于 OCR 前处理、扫描件增强、拍照文档清晰化等场景。

---

### 4. 标注图像复核

输入本地已标注图像和对应标注文件，经过以下处理流程：

```text
批量读取图像与标注 -> 多参数检测 -> IoU 匹配 -> F1 / Recall / Precision 多口径评分 -> HTML 报告
```

输出内容包括：

- 每张图像的最佳检测参数；
- 检测框、标注框和匹配结果可视化；
- 标签维度统计、尺寸分桶统计和模式汇总统计；
- 便于评审查看的 `summary_readable.csv`、`mode_summary.csv` 和 `index.html`。

该 demo 可用于展示 MoonVision 在实际标注数据复核、检测流程调参和可视化报告生成方面的扩展能力。

---

## 最终验收方式

项目最终提交前使用以下命令进行基础验证：

```powershell
moon check
moon test
moon run src/demo/object_counting
moon run src/demo/edge_detection
moon run src/demo/document_enhancement
```

对于本地标注数据复核场景，可使用以下命令进行快速验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -SampleFolders 346 -ExcludeRenameCopies
```

完整复核时可使用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_labeled_bacteria_review.ps1 -ForceRerun
```

项目验收重点包括：

- MoonBit 原生测试通过；
- 三个基础 demo 可运行并生成 HTML / PNG / SVG 输出；
- 标注图像复核脚本可生成 CSV 与 HTML 报告；
- README、LICENSE、申报书和仓库元信息保持一致；
- 不将本地生成的大量输出图片、CSV 或 HTML 结果纳入仓库提交。

---

## 项目许可证

- **许可证**：MIT

---

## 关键词

MoonBit, 图像处理, CV, 计算机视觉, 边缘检测, 形态学, 连通域分析, Sobel, Threshold, SVG, HTML, 可视化, 演示
