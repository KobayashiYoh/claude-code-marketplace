#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash)
# `git stash` を -u (--include-untracked) 無しで単体実行しようとした場合にブロックする。
# untrackedファイルを含めずにstashしてしまい、意図せずファイルが取りこぼされる事故を防ぐ。

set -euo pipefail

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

if [[ -z "$command" ]]; then
  exit 0
fi

# git stash / git stash push / git stash save (新規にstashを作る操作)のみを対象とする。
# pop / list / apply / drop / show / branch / clear 等は対象外。
if ! printf '%s' "$command" | grep -qE '(^|[;&|]) *git +stash *($|(push|save)( |$))'; then
  exit 0
fi

# -u / --include-untracked / -a / --all のいずれかが既に付いていれば許可する。
if printf '%s' "$command" | grep -qE -- '(-u\b|--include-untracked|-a\b|--all)'; then
  exit 0
fi

printf '%s\n' '{"decision":"block","reason":"git stash -u を使ってください"}'
exit 0
