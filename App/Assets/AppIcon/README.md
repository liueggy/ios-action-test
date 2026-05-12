# App Icon Placeholder

把你的应用图标 PNG 上传到这个目录后，再运行 GitHub Actions 打包。

推荐文件名：

```text
AppIcon60x60@2x.png   # 120x120，iPhone @2x
AppIcon60x60@3x.png   # 180x180，iPhone @3x
```

要求：

- PNG 格式
- 正方形
- 不要透明背景，iOS 图标通常需要不透明背景
- 文件名保持和上面一致

workflow 会在打包时自动把这些文件复制进 `.app`，并在 `Info.plist` 里声明为应用图标。
