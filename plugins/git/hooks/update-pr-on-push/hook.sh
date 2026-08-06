#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash)
# git push 実行時に、現在のブランチに紐づくAzure DevOpsのPRがあれば
# タイトル・説明文を最新の差分に合わせて更新するようClaudeに促す。

set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [[ -z "$command" ]]; then
  exit 0
fi

# git push (git push / git push origin <branch> / git push -u origin <branch> 等)を対象とする。
if ! printf '%s' "$command" | grep -qE '(^|[;&|]) *git +push([^a-zA-Z]|$)'; then
  exit 0
fi

context='git push が実行されました。pushが成功しており、現在のブランチに紐づくAzure DevOpsのプルリクエストが存在する場合は、以下の方針でPRのタイトル・説明文を最新化してください。

1. 現在のブランチに紐づくPRを検出する(例: `az repos pr list` で現在のブランチをソースとするPRを検索)。該当PRが無ければ何もしない。
2. `az repos pr show` で現在のタイトル・説明文を取得し、マージ先ブランチとの最新差分と照合する。実態とズレが無ければ更新せずその旨を報告して終了する(不要な更新をしない)。
3. ズレがある場合、`generate-pr-content` スキルと同じ方針で更新後のタイトル・本文案を作成する。
4. 更新前後の差分をユーザーに提示し、承認を得てから `az repos pr update` で反映する。既存の説明文にある手動追記(レビュアーへの補足コメント等)を意図せず消さないよう注意する。
5. 反映後、更新後のPRタイトル・URLを報告する。'

jq -n --arg ctx "$context" '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'
exit 0
