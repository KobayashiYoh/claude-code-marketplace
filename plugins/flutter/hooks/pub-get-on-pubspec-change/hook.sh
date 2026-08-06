#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
# pubspec.yaml / pubspec.lock の変更を検知したら `flutter pub get` を自動実行する。
# FVMを使っているプロジェクトでは `fvm flutter` に切り替える。
#
# FVM使用有無の判定は以下の優先順位で行う(組織固有の値はハードコードしない):
#   1. 環境変数 FLUTTER_CMD_PREFIX が設定されていればそれを `flutter` の前に付与する。
#   2. 変更されたファイルと同じディレクトリに .fvmrc または .fvm/fvm_config.json があれば `fvm` を使う。
#   3. どちらも無ければ素の `flutter` を使う。

set -euo pipefail

input="$(cat)"

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -z "$file_path" ]] && exit 0

filename="$(basename -- "$file_path")"
case "$filename" in
  pubspec.yaml|pubspec.lock) ;;
  *) exit 0 ;;
esac

[[ -f "$file_path" ]] || exit 0

project_dir="$(dirname -- "$file_path")"

flutter_cmd="flutter"
if [[ -n "${FLUTTER_CMD_PREFIX:-}" ]]; then
  flutter_cmd="${FLUTTER_CMD_PREFIX} flutter"
elif [[ -f "$project_dir/.fvmrc" || -f "$project_dir/.fvm/fvm_config.json" ]]; then
  flutter_cmd="fvm flutter"
fi

echo "[pub-get-on-pubspec-change] ${filename} の変更を検知しました。'${flutter_cmd} pub get' を実行します。"

if ! command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
  echo "[pub-get-on-pubspec-change] '${flutter_cmd%% *}' コマンドが見つからないためスキップします。" >&2
  exit 0
fi

(
  cd "$project_dir"
  # shellcheck disable=SC2086
  if $flutter_cmd pub get; then
    echo "[pub-get-on-pubspec-change] pub get に成功しました。"
  else
    echo "[pub-get-on-pubspec-change] pub get に失敗しました。内容を確認してください。" >&2
  fi
)

exit 0
