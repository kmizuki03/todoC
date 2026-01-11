## ToDoカレンダー（todoC）

iOS向けの「カレンダー型」タスク管理アプリです。日付ごとのToDo管理に加えて、タグ（カテゴリ）で整理できます。

## 主な機能

### カレンダー
- 複数カレンダーの作成・切り替え
- 「メイン」カレンダー選択時は、全カレンダーのタスクをまとめて表示
- 月表示カレンダー
- 左右スワイプで月移動
- 年月表示のタップで「今日」にジャンプ
- カレンダーの折りたたみ表示
- 日付選択で当日のタスクを表示
- 前月/翌月の移動
- 日付セルにタスク数（ドット）表示
- 土曜は青 / 日曜は赤 / 祝日は赤
- 祝日名の表示（例: 成人の日、振替休日）
- カレンダー管理（削除はメイン以外のみ）

### タスク管理
- タスク追加 / 編集 / 削除（スワイプ）
- 日付タップで追加（同じ日を続けてタップで追加画面）
- 完了/未完了の切り替え
- 時間指定（任意・デフォルトOFF）
- 場所の設定
- 時間指定タスクのローカル通知（作成/編集/完了/削除に追従）

### タグ（カテゴリ）
- タスクにタグを割り当て
- タグ管理（一覧/作成/編集/削除）
- カスタムカラー（8色）: レッド、ブルー、グリーン、オレンジ、パープル、ピンク、イエロー、グレー
- カスタムアイコン（12種 / SF Symbols）: フォルダ、買い物、仕事、勉強、家、健康、趣味、移動、食事、連絡、重要、フラグ
- ドラッグ&ドロップで並び替え
- タグ削除後も既存タスク表示のためにタグ情報を保持

### 表示
- タグ別グルーピング表示（ヘッダーの追従なし）
- 削除済みタグの表示（「(削除済み)」マーク）
- タグなしタスクは「未分類」
- ライト/ダーク/システムの表示切り替え
- 画面全体をカレンダー＋タスク一覧として表示（ナビバー最小化）
- カレンダー表記の日本語化（Locale: ja_JP）

## 技術スタック
- SwiftUI
- SwiftData
- UserNotifications（ローカル通知）
- iOS 26.2+

## 開発環境
- macOS
- Xcode（iOS 26.2 SDKが必要）

## 使い方
- 画面上部のカレンダー名メニューから、カレンダー追加/切替/管理ができます
- 「表示: システム/ライト/ダーク」から外観を切り替えできます
- 年月をタップすると「今日」に移動します
- 月表示は左右スワイプでも移動できます
- 時間指定タスクは、指定時刻に通知できます（初回起動時に許可を求めます）

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
      TaskNotificationManager.swift          # ローカル通知（許可/予約/取消/同期）
    Models/
      AppCalendar.swift                     # カレンダーモデル
      TodoItem.swift                        # タスクモデル
      Organization.swift                    # タグモデル（TaskFolder）
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