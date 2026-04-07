# WezTerm Config — 生成AI並列実行特化

複数の生成AI CLIツール（Claude Code等）を同時に実行・監視するためのWezTerm設定。

## 特徴

- iTerm2風の直感的なキーバインド
- ワンキーで2/3/4分割レイアウトを作成
- 起動時に自動で左右2ペイン分割 + ウィンドウ最大化
- macOS / Windows 両対応（同一設定ファイル）
- 非アクティブペインの自動暗転でフォーカスを視覚化
- スクロールバック50,000行（長大なAI出力に対応）
- タブバーを画面下部に常時表示（Gitブランチ + CWD）

## キーバインド

macOSでは `CMD`、Windowsでは `ALT` がメインモディファイア。

### ペイン操作

| 操作 | macOS | Windows |
|---|---|---|
| 縦分割（右） | `CMD+d` | `ALT+d` |
| 横分割（下） | `CMD+Shift+d` | `ALT+Shift+d` |
| ペインを閉じる | `CMD+w` | `ALT+w` |
| ズーム切替 | `CMD+Shift+Enter` | `ALT+Shift+Enter` |
| ペイン移動 | `CMD+ALT+矢印` | `CTRL+ALT+矢印` |
| ペインサイズ調整 | `CMD+Shift+矢印` | `ALT+Shift+矢印` |

### クイックレイアウト（共通）

| 操作 | キー |
|---|---|
| 2分割（左右） | `CTRL+Shift+2` |
| 3分割（左中右） | `CTRL+Shift+3` |
| 4分割（2×2グリッド） | `CTRL+Shift+4` |

新しいタブに指定のレイアウトを作成する。

### タブ操作

| 操作 | macOS | Windows |
|---|---|---|
| 新規タブ | `CMD+t` | `ALT+t` |
| 次のタブ | `CTRL+Tab` | `CTRL+Tab` |
| 前のタブ | `CTRL+Shift+Tab` | `CTRL+Shift+Tab` |
| 次のタブ（別） | `CMD+Shift+]` | `ALT+Shift+]` |
| 前のタブ（別） | `CMD+Shift+[` | `ALT+Shift+[` |
| タブ番号で切替 | `CMD+1-9` | `ALT+1-9` |

## 使い方の例

### AI 2つを並列実行

WezTermを起動するだけ。自動で左右2ペインになる。

### AI 4つを並列実行

`CTRL+Shift+4` で2×2グリッドを作成し、各ペインでAIを起動。

## 前提

- フォント: [JetBrains Mono](https://www.jetbrains.com/lp/mono/)（未インストールの場合はMenlo/Consolasにフォールバック）
- カラースキーム: Catppuccin Mocha（WezTerm内蔵）
