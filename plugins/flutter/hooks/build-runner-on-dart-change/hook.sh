#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
# *.dart / *.yaml / *.lock の変更を検知したら `dart run build_runner build` を自動実行する。
# FVMを使っているプロジェクトでは `fvm dart run build_runner build` に切り替える。
# 破壊的な --delete-conflicting-outputs 等のオプションは付けず、素の build_runner build に留める。

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

dart_cmd="dart"
if [[ -n "${FLUTTER_CMD_PREFIX:-}" ]]; then
  dart_cmd="${FLUTTER_CMD_PREFIX} dart"
elif [[ -f "$project_dir/.fvmrc" || -f "$project_dir/.fvm/fvm_config.json" ]]; then
  dart_cmd="fvm dart"
fi

if ! command -v "${dart_cmd%% *}" >/dev/null 2>&1; then
  echo "[build-runner-on-dart-change] '${dart_cmd%% *}' コマンドが見つからないためスキップします。" >&2
  exit 0
fi

echo "[build-runner-on-dart-change] $(basename -- "$file_path") の変更を検知しました。build_runner buildを実行します。"

(
  cd "$project_dir"
  # shellcheck disable=SC2086
  if $dart_cmd run build_runner build; then
    echo "[build-runner-on-dart-change] build_runner build は成功しました。"
  else
    echo "[build-runner-on-dart-change] build_runner build が失敗しました。内容を確認してください。" >&2
  fi
)

exit 0
