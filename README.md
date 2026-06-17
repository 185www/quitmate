# QuitMate - 戒烟戒酒助手

一款纯离线的戒烟戒酒综合干预应用。

## 三阶段模型
1. **认知觉醒** - 了解危害，建立改变动机
2. **行动改变** - 学会应对渴望的技巧
3. **维持防复发** - 建立健康习惯

## 技术栈
- Flutter 3.24+
- Riverpod 2.5+
- Drift (SQLite)
- flutter_secure_storage (AES-256加密)

## 隐私
所有数据仅存储在本地。不收集任何个人信息。无第三方追踪。

## 开发
```bash
cd apps/mobile
flutter pub get
flutter run
```

## 构建
```bash
flutter build apk --release
flutter build appbundle --release
```