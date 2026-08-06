#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash)
#
# 目的: git commit のメッセージが、プロジェクト側で定義したprefix規約(禁止パターン)に
# 一致していたらdenyする。
#
# 設定: このフック自体は特定のコミットメッセージ規約をハードコードしない。
# プロジェクトルート(gitリポジトリのトップレベル)の `.claude/commit-message-guard.json`
# に以下のキーで規約を定義する。
#   - "denyPattern": コミットメッセージがこの拡張正規表現(grep -E)にマッチしたらdenyする
#   - "reason": deny理由としてユーザーに表示するメッセージ
# 設定ファイルが無い、または "denyPattern" が無い場合は何もしない(enforceしない)。
#
# 設定例 (.claude/commit-message-guard.json):
# {
#   "denyPattern": "\\b(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\\([a-zA-Z0-9_./-]+\\) *:",
#   "reason": "コミットメッセージにスコープ付きprefix (例: feat(scope):) は使用しない規約です。"
# }

set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [[ -z "$command" ]]; then
  exit 0
fi

# git commit (git commit / git commit -m ... 等)以外は対象外。
if ! printf '%s' "$command" | grep -qE '(^|[;&|]) *git +commit([^a-zA-Z]|$)'; then
  exit 0
fi

# プロジェクト側の設定ファイルを探す(gitリポジトリのトップレベルのみ対応)。
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
config_file="$repo_root/.claude/commit-message-guard.json"

if [[ -z "$repo_root" || ! -f "$config_file" ]]; then
  exit 0
fi

deny_pattern="$(jq -r '.denyPattern // empty' "$config_file" 2>/dev/null || true)"

if [[ -z "$deny_pattern" ]]; then
  exit 0
fi

if printf '%s' "$command" | grep -qE "$deny_pattern"; then
  reason="$(jq -r '.reason // empty' "$config_file" 2>/dev/null || true)"
  if [[ -z "$reason" ]]; then
    reason='コミットメッセージが設定されたprefix規約 (denyPattern) に一致しました。'
  fi
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

exit 0
