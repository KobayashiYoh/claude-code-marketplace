#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
# .claude/settings*.json への書き込み後、permissions.allow / permissions.deny を
# アルファベット順にソートして書き戻す。

set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

if [[ -z "$file_path" ]]; then
  exit 0
fi

# 対象は .claude/settings*.json のみ
filename="$(basename -- "$file_path")"
case "$filename" in
  settings*.json) ;;
  *) exit 0 ;;
esac

case "$file_path" in
  */.claude/"$filename") ;;
  *) exit 0 ;;
esac

if [[ ! -f "$file_path" ]]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  # jq が無い環境では何もせず終了する(harnessを止めない)
  exit 0
fi

# JSONとして壊れている場合は何もしない
if ! jq empty "$file_path" >/dev/null 2>&1; then
  exit 0
fi

sorted_json="$(jq '
  if has("permissions") then
    .permissions |= (
      (if has("allow") then .allow |= sort else . end)
      | (if has("deny") then .deny |= sort else . end)
    )
  else
    .
  end
' "$file_path")"

if [[ -n "$sorted_json" ]] && [[ "$sorted_json" != "$(cat "$file_path")" ]]; then
  printf '%s\n' "$sorted_json" > "$file_path"
fi

exit 0
