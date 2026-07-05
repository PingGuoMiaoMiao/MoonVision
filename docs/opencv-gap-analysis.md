# MoonVision 与 OpenCV 差距分析

本文用于说明 MoonVision `v1.5` 与 OpenCV 的能力差距，重点服务项目定位、后续迭代和比赛答辩说明。

## 结论

MoonVision 当前不是 OpenCV 的移植项目，也不是 OpenCV 的完整替代品。它更准确的定位是：

```text
MoonBit-native 轻量级 imgproc / 基础计算机视觉算法库
```

如果对标完整 OpenCV，MoonVision 只覆盖很小一部分能力；如果只对标 OpenCV `imgproc` 中的基础算法层，MoonVision 已经覆盖一条可演示、可测试、可复用的轻量主线。

## 对标范围

OpenCV 是完整计算机视觉平台，主要能力包括：

- 核心矩阵与基础数据结构；
- 图像编解码；
- 图像处理；
- 视频读写；
- GUI 显示；
- 视频分析；
- 相机标定与 3D 重建；
- 特征点检测与匹配；
- 目标检测；
- 深度学习推理；
- 机器学习；
- 图像拼接；
- 计算摄影；
- 硬件加速与跨平台绑定。

MoonVision 当前只对标其中的轻量图像处理和基础视觉分析能力，不进入视频、GUI、DNN、3D 重建和完整特征工程。

## 当前已覆盖能力

### 图像基础结构

MoonVision 已提供：

- `GrayImage`
- `RgbImage`
- 图像尺寸读取；
- 像素读取；
- 像素写入；
- 数组导入导出；
- PNG 到 `RgbImage` 的适配；
- 灰度图 PNG 输出。

对应 OpenCV 中的基础图像矩阵能力，MoonVision 只覆盖二维灰度和 RGB 图像的轻量场景，没有覆盖 OpenCV `Mat` 的多通道、多深度、多维矩阵、ROI 视图、引用计数、SIMD 后端等能力。

### 基础像素操作

MoonVision 已提供：

- 灰度化；
- 固定阈值；
- Otsu 阈值；
- 自适应均值阈值；
- 反转；
- 亮度调整；
- 对比度调整。

与 OpenCV 相比，缺少：

- 完整颜色空间转换；
- HSV、Lab、YCrCb 等色彩空间；
- `inRange` 风格的多通道范围筛选；
- LUT 映射；
- alpha 通道处理；
- 多通道逐像素算术操作。

### 滤波与卷积

MoonVision 已提供：

- 通用整数卷积；
- Box Blur；
- Gaussian Blur；
- Sharpen；
- Median Blur；
- 边界复制采样。

与 OpenCV 相比，缺少：

- Bilateral Filter；
- Laplacian；
- Scharr；
- 方框滤波的积分图优化；
- separable filter；
- 自定义边界模式；
- 多通道滤波；
- 浮点核；
- 大图性能优化。

### 边缘检测

MoonVision 已提供：

- Sobel X；
- Sobel Y；
- 梯度幅值；
- 基础边缘提取；
- Canny。

与 OpenCV 相比，缺少：

- Laplace；
- Scharr；
- Hough Line；
- Hough Circle；
- Line Segment Detector；
- 更完整的非极大值抑制参数控制；
- 多尺度边缘检测。

### 形态学

MoonVision 已提供：

- Erosion；
- Dilation；
- Opening；
- Closing。

与 OpenCV 相比，缺少：

- Morphological Gradient；
- Top Hat；
- Black Hat；
- Hit-or-Miss；
- 自定义结构元素；
- 椭圆、十字等结构元素；
- 多次迭代参数；
- 多通道或灰度形态学扩展。

### 连通域与轮廓

MoonVision 已提供：

- Connected Components；
- Bounding Box；
- 面积过滤；
- 轮廓提取；
- 外轮廓与孔洞轮廓；
- 父子层级关系；
- 轮廓面积；
- 轮廓周长；
- 轮廓近似；
- 凸包；
- 最小面积旋转矩形；
- 圆度；
- 实心度。

这部分已经是 MoonVision 当前最接近 OpenCV `imgproc` 主线的能力块。

与 OpenCV 相比，缺少：

- 多种 contour retrieval mode；
- 多种 contour approximation mode；
- image moments；
- Hu moments；
- minEnclosingCircle；
- fitEllipse；
- matchShapes；
- pointPolygonTest 的完整行为；
- rotatedRectangleIntersection；
- connectedComponentsWithStats 的完整统计表语义；
- watershed；
- distanceTransform。

### 几何变换

MoonVision 已提供：

- 最近邻缩放；
- 水平翻转；
- 垂直翻转；
- 顺时针 90 度旋转；
- 逆时针 90 度旋转。

与 OpenCV 相比，缺少：

- 双线性插值；
- 双三次插值；
- 任意角度旋转；
- affine transform；
- perspective transform；
- warpAffine；
- warpPerspective；
- remap；
- resize 的多种插值模式；
- 图像金字塔；
- 子像素采样。

### 可视化与导出

MoonVision 已提供：

- PNG 输出；
- SVG bounding box overlay；
- HTML report；
- demo 输出组织。

与 OpenCV 相比，缺少：

- GUI 窗口显示；
- 鼠标键盘交互；
- 视频帧显示；
- 完整绘图 API；
- 文字绘制；
- 复杂图形绘制；
- 多格式图像读写。

## 覆盖度判断

### 对完整 OpenCV

MoonVision 当前覆盖度应按很低比例理解，约为：

```text
小于 5%
```

原因是 OpenCV 的主体能力远超 `imgproc`，还包括视频、深度学习、3D、特征点、目标检测、机器学习、GUI、平台加速等完整生态。

这个比例不代表 MoonVision 做得少，而是因为比较对象过大。比赛申报和答辩中不应宣称 MoonVision 是 OpenCV 替代品。

### 对 OpenCV imgproc

如果只看 `imgproc` 基础算法层，MoonVision 当前覆盖度约为：

```text
25% - 35%
```

已经覆盖的主线包括：

- 基础图像容器；
- 阈值；
- 滤波；
- Sobel；
- Canny；
- 形态学；
- 连通域；
- 轮廓；
- 轻量形状分析；
- 基础几何变换；
- 可视化报告。

未覆盖的关键主线包括：

- 完整颜色空间；
- 直方图；
- Hough；
- 模板匹配；
- 透视与仿射变换；
- 距离变换；
- Watershed；
- 图像金字塔；
- 绘图 API；
- 更完整的 contour/moments/shape matching。

### 对比赛目标

如果按当前申报方向评估：

```text
MoonBit-native 轻量级图像处理与基础计算机视觉算法库
```

当前完成度约为：

```text
85% - 90%
```

剩余主要是交付质量，而不是继续扩张功能边界：

- 最终测试记录；
- 最终审计文档；
- README 与申报书信息复核；
- GitHub 分支、tag、LICENSE 检查；
- demo 输出确认；
- 标注数据复核流程的结果说明。

## 后续扩展优先级

### P0：最终版收口

目标是保证比赛提交稳定。

- 固定 `v1.5` 分支；
- 补最终审计文档；
- 记录 `moon check` 和 `moon test` 结果；
- 记录三个基础 demo 运行结果；
- 记录细菌标注复核脚本的最小验证结果；
- 确认输出图片、CSV、HTML 不进入仓库；
- 创建最终 tag。

### P1：提高细菌检测命中率

目标是不要跑偏，继续围绕当前真实标注数据优化。

- 增加误检和漏检分类统计；
- 按标签、尺寸、亮度、长宽比拆分结果；
- 对高召回参数和高精度参数分别给出推荐；
- 改进候选框合并；
- 改进过大框拆分或过滤；
- 增加更直接的图表展示。

这部分最符合当前项目演示价值。

### P2：补齐轻量 imgproc 缺口

目标是扩展算法层，但仍保持轻量。

- Histogram；
- Histogram Equalization；
- Laplacian；
- Scharr；
- Morphological Gradient；
- Top Hat；
- Black Hat；
- Distance Transform；
- Hough Line；
- Template Matching；
- Bilinear Resize；
- Affine Transform；
- Perspective Transform。

这些功能可以作为 `v1.6` 或 `v2.0` 的规范来源。

### P3：不建议近期做

这些方向会显著扩大范围，不适合作为当前比赛最终版主线：

- 视频处理；
- 摄像头输入；
- GUI；
- DNN；
- 目标检测模型；
- 人脸识别；
- ORB/SIFT/SURF；
- 相机标定；
- 3D 重建；
- OpenCV binding。

## 推荐答辩口径

可以这样表述：

```text
MoonVision 并不是 OpenCV 的移植，也不试图复刻完整 OpenCV。
它参考 OpenCV imgproc 的经典算法体系，在 MoonBit 中实现一套轻量、可测试、可演示的基础图像处理算法层。
当前项目已经覆盖灰度化、阈值、滤波、边缘检测、形态学、连通域、轮廓、形状统计和可视化报告，能够支撑物体计数、边缘检测、文档增强和标注图像复核等场景。
后续如果继续扩展，会优先补充直方图、Hough、几何矫正、模板匹配等轻量 imgproc 能力，而不会转向视频、DNN 或 OpenCV 绑定。
```

## 风险说明

- 不应把 MoonVision 描述为 OpenCV 替代品。
- 不应把参考 OpenCV 文档描述为移植 OpenCV。
- 不应把当前细菌检测 demo 描述为通用医学检测模型。
- 不应把当前阈值、轮廓和规则检测结果描述为深度学习级别识别能力。
- 不应承诺视频、DNN、实时处理、跨平台 GUI 等当前未实现能力。

## 参考资料

- OpenCV Documentation: https://opencv-opencv.mintlify.app/
- OpenCV imgproc tutorial table: https://docs.opencv.org/4.x/d7/da8/tutorial_table_of_content_imgproc.html
- OpenCV imgproc API topics: https://docs.opencv.org/4.x/d7/dbd/group__imgproc.html
