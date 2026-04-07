# CLAUDE.md

## プロジェクト概要

生成AI並列実行に特化したWezTerm設定リポジトリ。macOS / Windows 両対応。

## ファイル構成

- `wezterm.lua` — WezTermの設定ファイル（Lua）
- `README.md` — キーバインド一覧・使い方ドキュメント

## ルール

- `wezterm.lua` を変更したら、必ず `README.md` のキーバインド一覧や説明も同期すること
- コミットメッセージは日本語で書くこと
- macOS / Windows 両対応を維持すること（`mod` 変数でプラットフォーム分岐）
- macOS固有の設定は `if is_macos then` ブロック内に書くこと
- キーバインドがOSのショートカットと競合しないか確認すること（特にmacOSの `CMD+Shift+3/4` 等）
