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
- **卷积滤波**：支持 Box Blur、Gaussian Blur、Sharpen 等常见滤波操作；
- **边缘检测**：支持 Sobel X/Y、梯度幅值计算和基础边缘提取；
- **形态学操作**：支持 Erosion、Dilation、Opening、Closing；
- **连通域分析**：支持 Connected Components，并提供 Bounding Boxes、面积过滤和目标计数；
- **可视化输出**：支持将处理结果导出为 PNG、SVG 或 HTML 报告；
- **Demo 示例**：
  - 物体计数，例如圆点、硬币、方块、细胞等目标计数；
  - 边缘检测，将输入图像转换为轮廓图；
  - 文档扫描增强，包括黑白化、去噪和基础增强处理。

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
      moon.pkg
      gray.mbt
      rgb.mbt
      codec.mbt

    ops/
      moon.pkg
      grayscale.mbt
      threshold.mbt
      invert.mbt
      brightness.mbt
      contrast.mbt
      ops_test.mbt

    filter/
      moon.pkg
      convolution.mbt
      box.mbt
      gaussian.mbt
      sharpen.mbt
      filter_test.mbt

    edge/
      moon.pkg
      sobel.mbt
      gradient.mbt
      edge_test.mbt

    morphology/
      moon.pkg
      erosion.mbt
      dilation.mbt
      opening.mbt
      closing.mbt
      morphology_test.mbt

    components/
      moon.pkg
      connected_components.mbt
      bounding_box.mbt
      components_test.mbt

    export/
      moon.pkg
      svg_overlay.mbt
      html_report.mbt

    demo/
      object_counting/
        moon.pkg
        main.mbt
      edge_detection/
        moon.pkg
        main.mbt
      document_enhancement/
        moon.pkg
        main.mbt

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

## 项目许可证

- **许可证**：MIT

---

## 关键词

MoonBit, 图像处理, CV, 计算机视觉, 边缘检测, 形态学, 连通域分析, Sobel, Threshold, SVG, HTML, 可视化, 演示
