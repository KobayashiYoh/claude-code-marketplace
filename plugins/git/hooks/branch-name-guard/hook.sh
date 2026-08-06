#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash)
#
# 目的: git checkout -b / git switch -c / git branch <name> 等、ブランチを新規作成する
# コマンドを検証し、保護ブランチへの直接作成と、命名規則違反をdenyする。
#
# 設定: このフック自体は保護ブランチ名や命名規則をハードコードしない。
# プロジェクトルート(gitリポジトリのトップレベル)の `.claude/branch-name-guard.json`
# に以下のキーで規約を定義する。
#   - "protectedBranches": 直接作成を禁止するブランチ名の配列 (例: ["main", "master", "develop"])
#   - "protectedReason": 保護ブランチへの作成をdenyする際の理由メッセージ
#   - "allowPattern": ブランチ名が一致すべき拡張正規表現(grep -E)。指定時、一致しない場合はdenyする
#   - "patternReason": "allowPattern" 不一致時にdeny理由としてユーザーに表示するメッセージ
# 設定ファイルが無い場合、または各キーが無い場合はそのチェックを行わない(enforceしない)。
#
# 設定例 (.claude/branch-name-guard.json):
# {
#   "protectedBranches": ["main", "master", "develop"],
#   "protectedReason": "保護ブランチには直接作成できません。",
#   "allowPattern": "^(feature|task|release)/[0-9]+_[a-z][a-z0-9_]*$",
#   "patternReason": "ブランチ名は {feature|task|release}/{番号}_{snake_case} の形式にしてください。例: feature/12345_my_feature, task/12345_fix_bug"
# }

set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [[ -z "$command" ]]; then
  exit 0
fi

# ブランチ作成コマンドからブランチ名を抽出する。
# 対応パターン: git checkout -b/--branch <name> / git switch -c/--create <name> / git branch <name>
branch=""

if [[ "$command" =~ (^|[\;\&\|])[[:space:]]*git[[:space:]]+checkout[[:space:]]+.*(-b|--branch)[[:space:]]+([^[:space:]]+) ]]; then
  branch="${BASH_REMATCH[3]}"
elif [[ "$command" =~ (^|[\;\&\|])[[:space:]]*git[[:space:]]+switch[[:space:]]+.*(-c|--create)[[:space:]]+([^[:space:]]+) ]]; then
  branch="${BASH_REMATCH[3]}"
elif [[ "$command" =~ (^|[\;\&\|])[[:space:]]*git[[:space:]]+branch[[:space:]]+([^[:space:]-][^[:space:]]*) ]]; then
  branch="${BASH_REMATCH[2]}"
fi

# 前後のクォート(', ")を取り除く(git checkout -b "feature/1_x" 等に対応)。
branch="${branch%\"}"
branch="${branch#\"}"
branch="${branch%\'}"
branch="${branch#\'}"

if [[ -z "$branch" ]]; then
  exit 0
fi

# プロジェクト側の設定ファイルを探す(gitリポジトリのトップレベルのみ対応)。
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
config_file="$repo_root/.claude/branch-name-guard.json"

if [[ -z "$repo_root" || ! -f "$config_file" ]]; then
  exit 0
fi

# 保護ブランチチェック
protected_match="$(jq -r --arg b "$branch" '(.protectedBranches // []) | index($b) // empty' "$config_file" 2>/dev/null || true)"

if [[ -n "$protected_match" ]]; then
  reason="$(jq -r '.protectedReason // empty' "$config_file" 2>/dev/null || true)"
  if [[ -z "$reason" ]]; then
    reason="'$branch' は保護ブランチです。直接作成できません。"
  fi
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

# 命名規則チェック
allow_pattern="$(jq -r '.allowPattern // empty' "$config_file" 2>/dev/null || true)"

if [[ -n "$allow_pattern" ]] && ! printf '%s' "$branch" | grep -qE "$allow_pattern"; then
  reason="$(jq -r '.patternReason // empty' "$config_file" 2>/dev/null || true)"
  if [[ -z "$reason" ]]; then
    reason="ブランチ名 '$branch' が設定された命名規則 (allowPattern) に一致しません。"
  fi
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

exit 0
