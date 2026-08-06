#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
# *.dart / *.yaml / *.lock の変更を検知したら `flutter test` を自動実行し、結果を報告する。
# FVM使用有無の判定は pub-get-on-pubspec-change と同じ方針。

set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file_path" ]] && exit 0

case "$file_path" in
  *.dart|*.yaml|*.lock) ;;
  *) exit 0 ;;
esac

[[ -f "$file_path" ]] || exit 0

# pubspec.yaml が見つかるまで上位ディレクトリを辿ってFlutterプロジェクトルートを特定する。
dir="$(dirname -- "$file_path")"
project_dir="$dir"
while [[ "$dir" != "/" && "$dir" != "." ]]; do
  if [[ -f "$dir/pubspec.yaml" ]]; then
    project_dir="$dir"
    break
  fi
  dir="$(dirname -- "$dir")"
done

if [[ ! -f "$project_dir/pubspec.yaml" ]]; then
  # Flutter/Dartプロジェクトでなければ何もしない
  exit 0
fi

flutter_cmd="flutter"
if [[ -n "${FLUTTER_CMD_PREFIX:-}" ]]; then
  flutter_cmd="${FLUTTER_CMD_PREFIX} flutter"
elif [[ -f "$project_dir/.fvmrc" || -f "$project_dir/.fvm/fvm_config.json" ]]; then
  flutter_cmd="fvm flutter"
fi

if ! command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
  echo "[test-on-dart-change] '${flutter_cmd%% *}' コマンドが見つからないためスキップします。" >&2
  exit 0
fi

echo "[test-on-dart-change] $(basename -- "$file_path") の変更を検知しました。testを実行します。"

(
  cd "$project_dir"
  # shellcheck disable=SC2086
  if $flutter_cmd test; then
    echo "[test-on-dart-change] test は成功しました。"
  else
    echo "[test-on-dart-change] test が失敗しました。内容を確認してください。" >&2
  fi
)

exit 0
