# 玻璃待办 → 个人工具箱开发地图

> 当前项目：`ios-action-test / GlassTasks`
> 目标：从轻量待办 App，逐步演进为一个「个人效率工具箱 / 个人操作面板 / 本地优先的个人 OS」。

---

## 1. 产品定位升级

当前 App 的核心是：

- 待办任务
- 日历写入
- 快捷电话 / 短信 / 邮箱 / 网页 / 地图
- 简单设置与外观主题

可以升级为：

> 一个面向个人日常、学习、工作、生活的本地优先工具箱，集中管理任务、笔记、日历、快捷动作、信息收集、习惯、文件、链接、联系人与自动化动作。

关键词：

- 本地优先
- 轻量
- 快速记录
- 快捷动作
- 个人仪表盘
- 模块化工具箱
- 可扩展
- iOS 原生体验

---

## 2. 交互体验重构方向

### 2.1 首页从「任务列表」升级为「今日仪表盘」

现在首页是普通表格列表，建议改成 Dashboard：

#### 首页结构

1. 顶部问候卡片
   - 上午 / 下午 / 晚上问候
   - 当前模式：学习 / 工作 / 生活 / 默认
   - 今天日期
   - 今日完成度

2. 今日重点卡片
   - 今日任务数量
   - 逾期任务数量
   - 即将到期任务
   - 今日日历事件

3. 快速捕捉入口
   - 新建任务
   - 快速笔记
   - 添加链接
   - 添加日程
   - 记录灵感

4. 工具宫格
   - 电话
   - 短信
   - 邮件
   - 网页
   - 地图
   - 日历
   - 剪贴板
   - 扫码
   - OCR
   - 文件
   - 计时器
   - 习惯打卡

5. 最近内容
   - 最近任务
   - 最近笔记
   - 最近链接
   - 最近打开的工具

---

### 2.2 视觉组件重构

当前大多是 `UITableViewCell`，可以逐步升级：

#### 阶段 1：继续 UIKit，但自定义卡片 Cell

- `DashboardHeaderCell`
- `MetricCardCell`
- `QuickActionGridCell`
- `TaskPreviewCell`
- `NotePreviewCell`

视觉风格：

- 圆角：16～24
- 背景：`.secondarySystemGroupedBackground`
- 阴影：轻量，不要太重
- SF Symbols 图标
- 动态色适配明暗主题
- accent color 跟随设置

#### 阶段 2：引入 UICollectionView Compositional Layout

首页、工具箱页、笔记列表都可以用：

- `UICollectionViewCompositionalLayout`
- section-based dashboard
- 横向滚动卡片
- 两列 / 三列工具宫格

#### 阶段 3：可选迁移部分 SwiftUI

不建议一开始全部迁移 SwiftUI。可以先在 UIKit 中嵌入 SwiftUI 组件：

- Dashboard 卡片
- 图表
- 设置页
- 空状态页

使用：

```swift
UIHostingController(rootView: SomeSwiftUIView())
```

---

## 3. 信息架构建议

建议从当前 3 个 tab：

```text
待办 / 快捷 / 设置
```

升级为 4～5 个 tab：

```text
今日 / 工具 / 资料 / 自动化 / 设置
```

或者更轻量：

```text
今日 / 工具箱 / 记录 / 设置
```

### 推荐版本

#### Tab 1：今日

个人仪表盘：

- 今日待办
- 今日日历
- 逾期提醒
- 快速记录
- 今日习惯
- 今日摘要

#### Tab 2：工具箱

所有快捷能力集中：

- 联系工具
- 系统跳转
- 文本工具
- 图片工具
- 文件工具
- 网络工具
- 学习工具
- 开发工具

#### Tab 3：记录

个人知识 / 信息收集：

- 快速笔记
- 灵感
- 链接收藏
- 剪贴板历史
- 图片 OCR
- 语音备忘，可后续做

#### Tab 4：设置

- 外观
- 模式
- 快捷项配置
- 数据导入导出
- 隐私
- 关于

---

## 4. 功能模块发散规划

### 4.1 待办模块升级

当前待办功能比较基础，可增强：

- 项目 / 分组
- 标签
- 优先级
- 子任务
- 重复任务
- 提醒时间
- 截止时间
- 日历双向同步，后期
- 搜索
- 批量操作
- 今日 / 未来 / 已完成 / 逾期
- 看板视图

可借鉴：

- Things 3：Today / Upcoming / Anytime / Someday
- Todoist：自然语言输入、项目、标签、优先级
- TickTick：习惯、番茄钟、日历
- Apple Reminders：列表、智能列表

---

### 4.2 快速记录 / 笔记模块

新增一个轻量笔记系统：

- 快速文本记录
- Markdown 支持
- 标签
- 收藏
- 搜索
- Pin 置顶
- 任务与笔记互转
- 链接预览
- 图片附件
- 导出 Markdown

可借鉴：

- Apple Notes
- Bear
- Drafts
- Obsidian
- Logseq

开源参考：

- Markdown 渲染：`swift-markdown`、`Down`
- 编辑器：`CodeEditor`、`MarkdownTextView` 类项目

---

### 4.3 工具箱模块

将「快捷操作」扩展成真正的工具箱。

#### 联系类

- 快速拨号
- 快速短信
- 快速邮件
- 常用联系人
- 模板消息

#### 系统类

- 打开日历
- 打开设置
- 打开定位 / 地图
- 打开 Wi-Fi / 蓝牙设置，受 iOS 限制，只能部分支持
- 打开常用 App URL Scheme

#### 文本类

- 大小写转换
- URL 编码 / 解码
- Base64 编码 / 解码
- JSON 格式化
- Markdown 预览
- 字数统计
- 正则测试
- 文本去重
- 文本排序

#### 图片类

- OCR 识别
- 二维码识别
- 二维码生成
- 图片压缩
- 图片转 PDF
- 拼图 / 长图，后期

#### 文件类

- 文件收藏
- PDF 预览
- 文本文件查看
- 分享导入
- iCloud Drive 文件选择

#### 时间类

- 计时器
- 番茄钟
- 世界时间
- 日期间隔计算
- 倒数日

#### 学习类

- 单词卡片
- 公式速查
- 复习计划
- 错题记录
- 阅读清单

#### 开发类

- JSON 格式化
- JWT 解码
- Hash 计算
- UUID 生成
- 时间戳转换
- URL 参数解析

可借鉴：

- Toolbox Pro
- Scriptable
- Actions App
- Raycast
- Alfred
- Shortcuts
- DevUtils
- DevToys

---

### 4.4 自动化模块

由于 iOS 限制，App 内不能像桌面后台常驻，但可以做：

- URL Scheme 触发动作
- Shortcuts 集成
- 分享扩展，后期
- Widget，后期
- App Intents，后期
- Siri Shortcuts，后期

建议设计一个内部 Action 模型：

```swift
struct ToolboxAction {
    let id: UUID
    let title: String
    let icon: String
    let category: ActionCategory
    let inputType: ActionInputType
    let outputType: ActionOutputType
    let handler: ActionHandler
}
```

未来每个工具都是一个 Action。

---

### 4.5 数据中心模块

后期可以把所有数据统一为本地数据库：

- Task
- Note
- Link
- Habit
- ActionHistory
- Attachment
- Tag
- Project

建议从 `UserDefaults` 逐步迁移到：

1. JSON 文件存储，容易调试
2. SQLite
3. Core Data / SwiftData

如果最低 iOS 17，可以考虑 SwiftData：

- 更现代
- 和 SwiftUI 适配好
- 但 UIKit 项目中也可以用

如果要稳定和可控，SQLite 更适合。

开源参考：

- GRDB.swift
- SQLite.swift
- Realm，可选但偏重

推荐：

> 如果坚持 UIKit + 轻量原生，优先考虑 GRDB.swift 或 SwiftData。

---

## 5. 开源工具 / SDK 集成建议

### 5.1 图标与视觉

- SF Symbols：首选，系统原生
- SwiftUI Charts：图表，iOS 16+
- Charts：danielgindi/Charts，老牌图表库

### 5.2 Markdown / 文本

- apple/swift-markdown
- iwasrobbed/Down
- MarkdownUI

### 5.3 数据库

- groue/GRDB.swift
- stephencelis/SQLite.swift

### 5.4 网络与链接预览

- LinkPresentation：系统框架，生成链接预览
- SwiftSoup：HTML 解析

### 5.5 图片 / OCR / 二维码

- Vision：系统 OCR / Barcode
- CoreImage：二维码生成
- PhotosUI：选择图片

### 5.6 日历 / 提醒事项

- EventKit：当前已用日历
- EventKit Reminders：可集成系统提醒事项，但权限和 API 要单独处理

### 5.7 自动化 / 系统集成

- App Intents
- Shortcuts
- WidgetKit
- ActivityKit
- URL Scheme

---

## 6. 分阶段开发路线

### Phase 0：稳定当前版本

目标：先把现有 App 打磨稳定。

任务：

- 修复主题 bug
- 修复大标题
- 修复短信 URL
- 修复数据共享
- 图标规范化
- Release 版本号自动递增
- Info.plist 从 workflow 移入仓库
- 增加简单 smoke test 脚本

---

### Phase 1：UI 体验重构

目标：让 App 看起来更像现代 iOS 工具，而不是普通表格 Demo。

任务：

- 新增 Dashboard 首页
- 重构任务 cell 为卡片样式
- 快捷操作改为宫格布局
- 设置页保留表格，但美化说明区域
- 空状态页优化
- 明暗主题完整适配
- Accent 色贯穿图标和按钮

---

### Phase 2：工具箱扩展

目标：让 App 不再局限待办。

新增工具：

- 文本字数统计
- URL 编码 / 解码
- Base64 编解码
- JSON 格式化
- 时间戳转换
- UUID 生成
- 二维码生成
- OCR 入口
- 链接收藏

---

### Phase 3：快速记录与资料库

目标：变成个人信息收集工具。

新增：

- 快速笔记
- 链接收藏
- 标签系统
- 搜索
- Markdown 预览
- 分享摘要
- 导出 Markdown / JSON

---

### Phase 4：任务系统高级化

目标：接近 Things / Todoist 的轻量版本。

新增：

- 项目
- 标签
- 子任务
- 重复任务
- 智能列表
- 今日 / 未来 / 逾期
- 任务与笔记互转
- 看板视图，可选

---

### Phase 5：个人自动化平台

目标：形成个人操作中心。

新增：

- App Intents
- Shortcuts 集成
- Widget
- URL Scheme
- 自定义动作
- 动作历史
- 常用动作置顶

---

## 7. 推荐优先级

如果现在马上开始改，建议顺序是：

1. 首页 Dashboard
2. 工具箱宫格
3. 任务 Cell 美化
4. 快速记录 / 笔记
5. 文本工具集
6. OCR / 二维码工具
7. 数据层从 UserDefaults 迁移
8. App Intents / Widget

---

## 8. 下一步可直接实现的版本

建议下一版叫：

```text
GlassTools v0.4
```

定位：

> 从「玻璃待办」升级为「玻璃工具箱」雏形。

本版本改动：

- Tab 改为：今日 / 工具 / 设置
- 今日页加入仪表盘卡片
- 工具页使用宫格入口
- 任务列表改为更美观的卡片
- 继续保留当前任务、日历、快捷电话、短信、邮件、地图功能
- 预留笔记和文本工具入口

---

## 9. 设计原则

1. 不堆功能，先保证每个功能 3 秒内可用。
2. 首页只放用户每天最需要的东西。
3. 所有工具都能从搜索或宫格快速进入。
4. 默认本地存储，不强制登录。
5. 明暗主题必须完整适配。
6. 每个模块都可以独立关闭或隐藏。
7. 数据可导出，避免锁死用户。
8. 先 UIKit 稳定实现，再考虑 SwiftUI 增强。
