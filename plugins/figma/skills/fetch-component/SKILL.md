---
name: fetch-component
description: Figma APIから指定ファイル/ノードのコンポーネント情報(構造・スタイル・プロパティ)を取得するスキル。「Figmaのこのコンポーネントの情報を取って」等の指示で使用する。
---

# fetch-component

Figma APIを使い、指定したファイル/ノードのコンポーネント情報を取得する。取得のみを行い、特定のフレームワーク・プロジェクトへのマッピング(実装コードへの変換等)はこのスキルの対象外とする。

## 設定の前提

Figmaのアクセストークンは環境変数(`FIGMA_API_TOKEN`。後方互換として `FIGMA_TOKEN` も参照する)から読み込み、このスキル内にハードコードしない。ファイルキー・ノードIDはユーザー入力(Figmaの共有URLからも抽出可能)から取得する。

## 手順

1. 対象のFigma URL(例: `https://www.figma.com/design/<fileKey>/...?node-id=1234-5678`)をユーザーから受け取る。指定がない場合はURLを質問する。
2. `FIGMA_API_TOKEN` が設定されているか確認する(`echo $FIGMA_API_TOKEN`)。無ければユーザーに設定方法(Figmaの設定ページ → Settings → Personal access tokens でトークンを発行)を案内して終了する。
3. 付属のスクリプトでFigma REST APIの `GET /v1/files/:file_key/nodes?ids=:node_id` を呼び出し、ノードのJSONを取得・軽量化する。

   ```bash
   node .claude/skills/fetch-component/fetch-figma-component.js --url "<FigmaのURL>"
   ```

   トークンを直接指定する場合:

   ```bash
   node .claude/skills/fetch-component/fetch-figma-component.js --url "<FigmaのURL>" --token "<APIトークン>"
   ```

   JSONをファイルに保存する場合:

   ```bash
   node .claude/skills/fetch-component/fetch-figma-component.js --url "<FigmaのURL>" --output figma-component.json
   ```

   スクリプトは取得したJSONから、UI実装に不要なメタデータ(`absoluteBoundingBox` 等の絶対座標、`exportSettings`、`pluginData`、`componentPropertyDefinitions` など)を自動的に除外して軽量化する。詳細な除外キー一覧はスクリプト冒頭の `KEYS_TO_REMOVE` を参照。
4. 取得したJSONから、実装の参考になる情報(コンポーネント名、階層構造、主要スタイル値)を整理して提示する。
5. 画像として書き出しが必要な場合は `GET /v1/images/:file_key` エンドポイントを使い、指定フォーマット(PNG/SVG等)でエクスポートする(このスクリプトの対象外)。

## 注意事項

- 取得したデザイン情報を特定のUIフレームワーク(Vue/React/Flutter等)のコードに変換する後続処理は、このスキルには含めない。必要であれば呼び出し元プロジェクト固有のスキル/手順に委ねる。
- APIトークンやレスポンスに含まれる機微情報をログや出力にそのまま貼り付けない。
