# Egg Tool App Icon

当前目录包含 Egg Tool 的应用图标资源。

已生成：

```text
AppIcon60x60@2x.png   # 120x120，iPhone @2x
AppIcon60x60@3x.png   # 180x180，iPhone @3x
AppIcon1024.png       # 源图备份，用于后续重新导出不同尺寸
```

要求：

- PNG 格式
- 正方形
- 不透明背景
- `@2x` / `@3x` 文件名保持一致

workflow 会在打包时自动把 `AppIcon60x60@2x.png` 和 `AppIcon60x60@3x.png` 复制进 `.app`，并在 `Info.plist` 里声明为应用图标。
