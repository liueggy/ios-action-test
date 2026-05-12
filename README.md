# Egg Tool

Egg Tool 是一个面向 iOS 的个人工具箱雏形：从待办、日历和快捷操作出发，逐步扩展为今日仪表盘、工具箱、快速记录和个人自动化中心。

当前版本使用稳定的 UIKit 原生控件和手写 IPA 打包流程，通过 GitHub Actions 在 macOS runner 上编译并打包 unsigned IPA。

## 当前功能

- 今日仪表盘：问候、任务概览、快速入口、接下来任务
- 任务管理：待处理、已完成、全部、逾期、优先级
- 日历写入：可把任务同步写入系统日历
- 工具箱宫格：电话、短信、邮件、网页、地图、日历、摘要复制和分享
- 文本工具：字数统计、URL 编解码、Base64 编解码、JSON 格式化、UUID 生成、时间戳
- 快速笔记：本地记录、搜索、置顶、复制、分享
- 个性化设置：明暗主题、强调色、学习/工作/生活/默认模式
- 链接收藏：保存网页/资料链接、搜索、置顶、打开、复制、分享
- 二维码工具：文本/链接生成二维码、复制图片、分享图片
- OCR 工具：从相册选择图片，本地识别中英文文字，复制/分享结果
- 阅读器：导入 TXT/Markdown/JSON/代码/图片/PDF/Office 等多格式文件，支持内置阅读和 Quick Look 预览
- 数据备份：任务、笔记、链接统一 JSON 导出和导入恢复

## 打包方式

进入 Actions 页面运行：

```text
Build Tasks IPA
```

成功后会生成：

```text
EggTool-unsigned-ipa
```

并发布到 Release：

```text
glass-tasks-v3
```

## 自定义应用图标

你可以把自己的 PNG 图标上传到：

```text
App/Assets/AppIcon/
```

推荐文件名：

```text
AppIcon60x60@2x.png   # 120x120
AppIcon60x60@3x.png   # 180x180
```

要求：

- PNG 格式
- 正方形
- 建议不透明背景
- 文件名保持一致

上传后重新运行 Action，workflow 会自动把图标复制进 `.app` 并写入 IPA。

## 注意

生成的是 unsigned IPA。真机安装前仍需要你自己用证书和 provisioning profile 重签名。
