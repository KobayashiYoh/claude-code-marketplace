---
name: sync-copilot
description: ".claude/skills/を単一ソースとして、GitHub Copilot向けの参照ファイル(.github/prompts/または.github/skills/)をDRYに再生成するスキル。「Copilotに同期して」「copilotのプロンプトを更新して」等の指示で使用する。"
---

# sync-copilot

`.claude/skills/` を唯一の単一ソース(single source of truth)とし、GitHub Copilot向けの薄い参照ファイルを生成・再生成する。内容そのものを複製せず、パーマリンク参照のみのDRYな構成にする。

## 前提

- 単一ソースは常に `.claude/skills/<skill-name>/SKILL.md` である。Copilot側のファイルに実質的な手順を書き写さない。
- 出力先はプロジェクトの慣習に合わせて `.github/prompts/` または `.github/skills/` のいずれかを使う。判断に迷う場合:
  1. 既に `.github/prompts/` か `.github/skills/` のどちらかが存在すればそれを使う。
  2. どちらも無ければユーザーに確認するか、`.github/prompts/` をデフォルトとする。

## 手順

1. `.claude/skills/` 配下の各スキルディレクトリを列挙する(`SKILL.md` を持つディレクトリのみ対象)。
2. 各スキルについて、対応するリモートリポジトリ上のパーマリンクURLを組み立てる。
   - リモートURL(`git remote get-url origin`)とカレントブランチ、またはコミットハッシュ(`git rev-parse HEAD`)から `https://github.com/<owner>/<repo>/blob/<commit-sha>/.claude/skills/<skill-name>/SKILL.md` の形式のパーマリンクを生成する。
   - コミットされていない変更しかない場合はブランチ名ベースのURLで代替し、その旨をユーザーに伝える。
3. 出力先ディレクトリ(`.github/prompts/` 等)に、スキルごとに1ファイルを生成・上書きする。ファイル名はスキル名に準じる(例: `commit.prompt.md`。拡張子や命名規則はプロジェクトの既存ファイルがあればそれに合わせる)。
4. 生成するファイルの中身は以下の構成のみとする。実際の手順を複製しない。
   - 元スキルへのパーマリンク1行。
   - Copilot固有の注意点がある場合のみ、それを追記(例: Copilotのプロンプト実行方式に起因する制約など)。無い場合は追記しない。
5. 生成後、変更されたファイル一覧を差分として表示し、意図しないファイルが上書きされていないか確認する。
6. コミットはユーザーの明示的な指示がある場合のみ行う(`git`プラグインの`commit`スキルを利用してよい)。

## 注意事項

- `.claude/skills/` の内容をそのままコピー&ペーストして `.github/` 側に転記しない。必ずパーマリンク参照に留める。
- 出力先に手動で追加された独自ファイル(このスキルが生成したものではないファイル)を誤って削除しない。生成対象は「`.claude/skills/`に対応が存在するファイル」のみとする。
