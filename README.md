## ToDoカレンダー（todoC）

iOS向けの「カレンダー型」タスク管理アプリです。日付ごとのToDo管理に加えて、タグ（カテゴリ）で整理できます。

## 主な機能

### カレンダー
- 複数カレンダーの作成・切り替え
- 「メイン」カレンダー選択時は、全カレンダーのタスクをまとめて表示
- 月表示カレンダー
- 日付選択で当日のタスクを表示
- 前月/翌月の移動
- 日付セルにタスク数（ドット）表示
- 土曜は青 / 日曜は赤 / 祝日は赤
- 祝日名の表示（例: 成人の日、振替休日）
- カレンダー管理（削除はメイン以外のみ）

### タスク管理
- タスク追加 / 編集 / 削除（スワイプ）
- 完了/未完了の切り替え
- 時間指定（任意・デフォルトOFF）
- 場所の設定

### タグ（カテゴリ）
- タスクにタグを割り当て
- タグ管理（一覧/作成/編集/削除）
- カスタムカラー（8色）: レッド、ブルー、グリーン、オレンジ、パープル、ピンク、イエロー、グレー
- カスタムアイコン（12種 / SF Symbols）: フォルダ、買い物、仕事、勉強、家、健康、趣味、移動、食事、連絡、重要、フラグ
- ドラッグ&ドロップで並び替え
- タグ削除後も既存タスク表示のためにタグ情報を保持

### 表示
- タグ別セクション表示
- セクションの折りたたみ
- 削除済みタグの表示（「(削除済み)」マーク）
- タグなしタスクは「未分類」
- ライト/ダーク/システムの表示切り替え

## 技術スタック
- SwiftUI
- SwiftData
- iOS 17+

## 開発環境
- macOS
- Xcode 15 以降（iOS 17 SDKが必要）

## 使い方
- 画面上部のカレンダー名メニューから、カレンダー追加/切替/管理ができます
- 「表示: システム/ライト/ダーク」から外観を切り替えできます

## データモデル（SwiftData）

### AppCalendar
- `name`: カレンダー名
- `colorHex`: テーマ色（Hex文字列）

### TodoItem
- `title`: タスク名
- `date`: 日付
- `isTimeSet`: 時間指定の有無
- `location`: 場所
- `isCompleted`: 完了状態
- `calendar`: 所属カレンダー
- `folder`: タグ（`TaskFolder` を直接参照）
- `tagName`, `tagColorName`, `tagIconName`: タグ情報バックアップ（タグ削除後の表示用）

### TaskFolder（タグ）
- `name`: タグ名
- `colorName`: カラー名（例: `red`, `blue`）
- `iconName`: アイコン名（SF Symbols）
- `sortOrder`: 並び順
- `isTemplate`: テンプレートタグかどうか

## プロジェクト構成

```text
ToDoカレンダー/
  ToDoカレンダー/
    ToDo______App.swift                     # アプリエントリポイント
    ContentView.swift                       # メイン画面
    Extensions/
      AppAppearance.swift                   # 外観設定（システム/ライト/ダーク）
      DateExtensions.swift                  # 日付ユーティリティ
      JapaneseHoliday.swift                 # 日本の祝日判定/祝日名
    Models/
      AppCalendar.swift                     # カレンダーモデル
      TodoItem.swift                        # タスクモデル
      Organization.swift                    # Tagモデル（TaskFolder）
    Views/
      Components/
        DayCellView.swift                   # カレンダー日付セル
        TodoRowView.swift                   # タスク行
      Screens/
        AddTodoView.swift                   # タスク追加画面
        CalendarManagerView.swift            # カレンダー管理（メイン以外削除）
        EditTodoView.swift                  # タスク編集画面
        TodoListView.swift                  # タスク一覧
        TemplateFolderManagerView.swift     # タグ管理画面
  ToDoカレンダー.xcodeproj/
```

## ライセンス
Private