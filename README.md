# 🐷 小豬公 (PiggyBank)

一個使用 Flutter 開發的跨平台記帳應用程式，支援 iOS、Android、macOS、Windows、Linux 和 Web。

## 📱 功能特點

### 基本記帳
- 收入與支出記錄
- 支援多筆記錄（多個帳戶/錢包）
- 類別管理（自訂分類）
- 備註與發票號碼記錄

### 財務分析
- 圖表統計功能
- 收支趨勢分析

### 安全與隱私
- 密碼鎖定功能
- 本地資料儲存（SQLite）

### 跨平台支援
- iOS
- Android
- macOS
- Windows
- Linux
- Web

## 🛠 技術架構

### 框架與語言
- **Flutter** 3.11+
- **Dart** 3.11+

### 狀態管理
- **flutter_bloc** (BLoC 模式)

### 資料儲存
- **sqflite** (本地 SQLite 資料庫)
- **shared_preferences** (設定儲存)

### 主要依賴
| 套件 | 用途 |
|------|------|
| flutter_bloc | 狀態管理 |
| sqflite | SQLite 資料庫 |
| path_provider | 檔案路徑取得 |
| fl_chart | 圖表統計 |
| equatable | 物件比較 |
| uuid | ID 生成 |
| url_launcher | 開啟外部連結 |
| permission_handler | 權限管理 |
| device_info_plus | 裝置資訊 |
| open_filex | 開啟檔案 |

## 📁 專案結構

```
lib/
├── main.dart                 # 應用程式入口
├── blocs/                    # BLoC 狀態管理
│   ├── category/            # 類別管理
│   ├── transaction/         # 交易記錄
│   └── wallet/              # 帳戶管理
├── models/                  # 資料模型
│   ├── category.dart
│   ├── transaction.dart
│   └── wallet.dart
├── repositories/            # 資料倉儲
├── screens/                 # 螢幕頁面
│   ├── home_screen.dart     # 首頁
│   ├── add_transaction_screen.dart  # 新增交易
│   ├── category_screen.dart # 類別管理
│   ├── wallet_screen.dart   # 帳戶管理
│   ├── stats_screen.dart    # 統計分析
│   ├── settings_screen.dart # 設定
│   ├── lock_screen.dart     # 鎖定畫面
│   └── main_screen.dart     # 主畫面
├── services/                # 服務層
│   └── database_service.dart
└── widgets/                 # 共用元件
```

## 🚀 開始使用

### 環境需求
- Flutter SDK 3.11+
- Dart SDK 3.11+

### 安裝步驟

1. 克隆專案
```bash
git clone <repository-url>
cd piggy_bank
```

2. 安裝依賴
```bash
flutter pub get
```

3. 執行專案
```bash
flutter run
```

### 建構 APK

```bash
flutter build apk --release
```

### 建構 iOS

```bash
flutter build ios --release
```

## 📄 授權

本專案僅供個人學習使用。
