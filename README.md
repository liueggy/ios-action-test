# 玻璃待办 / iOS Action Test

这是一个轻量 iOS UIKit 应用，用于验证 GitHub Actions 能否在 macOS runner 上编译并打包 unsigned IPA。

当前版本采用稳定的 UIKit 系统控件和手写 IPA 打包流程，不再依赖液态玻璃专用代码。

## 打包方式

进入 Actions 页面运行：

```text
Build Tasks IPA
```

成功后会生成：

```text
GlassTasks-unsigned-ipa
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
