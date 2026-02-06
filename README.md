# medium-article

Medium記事公開用リポジトリ

## ⚠️ 重要な注意事項

**Medium APIは非推奨（deprecated）です。** このリポジトリのスクリプトは動作しない可能性が高いです。

**推奨**: Mediumへの投稿は手動で行ってください → https://medium.com/new-story

## 概要

このリポジトリはMediumへの記事公開を試みます。
- **PR作成**: 下書きとして投稿を試行
- **PRマージ**: 公開として投稿を試行

## ディレクトリ構成

```
medium-article/
├── posts/              # 記事
├── scripts/            # デプロイスクリプト
├── .github/workflows/  # GitHub Actions
└── medium_article_ids.json  # 記事ID管理
```

## ワークフロー

| イベント | アクション | 状態 |
|----------|-----------|------|
| PR作成・更新 | 下書き投稿を試行 | Draft (試行) |
| PRマージ | 公開投稿を試行 | Public (試行) |

## 記事の作成

`posts/` ディレクトリにMarkdownファイルを作成します。

## Frontmatter

```yaml
---
title: "記事タイトル"
tags:
  - programming
  - technology
canonical_url: ""
---
```

## 必要な設定

### GitHub Secrets
- `MEDIUM_TOKEN`: Medium Integration Token（オプション、動作保証なし）
- `DISCORD_WEBHOOK`: Discord通知用Webhook URL（オプション）

### トークン取得方法（動作保証なし）
1. [Medium](https://medium.com) にログイン
2. Settings → Security and apps → Integration tokens
3. 「Get integration token」をクリック

## 代替手段

Medium APIが動作しない場合の代替手段:

1. **手動投稿**: https://medium.com/new-story
2. **Import機能**: Medium のimport機能でMarkdownをインポート
3. **クロスポスト**: DEV.to等で公開後、canonical URLを設定してMediumに手動投稿

## 関連リンク

- [granizm-blog](https://github.com/granizm/granizm-blog) - アイデア・下書き管理
- [Medium](https://medium.com)
