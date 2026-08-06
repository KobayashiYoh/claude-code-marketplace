---
name: create-worktree
description: 指定したブランチ用のgit worktreeを`.worktrees/`配下に作成するスキル。必要であればVSCodeを別ウィンドウで開く。「worktreeを作って」等の指示で使用する。
---

# create-worktree

作業用のブランチに対応するgit worktreeを作成する。

## 手順

1. 対象ブランチ名を確認する。指定が無い場合はユーザーに確認するか、現在のタスク内容から `create-branch` スキルと同様の方法でkebab-caseのブランチ名を提案する。
2. ブランチが既に存在するか `git branch --list <branch>` で確認する。
   - 存在しない場合は、後続の `git worktree add` コマンドでブランチも同時に作成する(`-b`オプション)。
   - 存在する場合は既存ブランチを利用する。
3. リポジトリ直下に `.worktrees/` ディレクトリを想定し、以下のいずれかを実行する。
   - 新規ブランチの場合: `git worktree add -b <branch> .worktrees/<branch> <base-branch>`
   - 既存ブランチの場合: `git worktree add .worktrees/<branch> <branch>`
4. `.worktrees/` がリポジトリの `.gitignore` に含まれているか確認し、含まれていなければユーザーに追記してよいか確認する。
5. worktree作成後、パスをユーザーに報告する。
6. ユーザーから明示的にエディタで開く指示があった場合のみ、`code <path>` を実行してVSCodeを別ウィンドウで開く。指示が無ければ開かない。

## 注意事項

- 既に同じパスにworktreeが存在する場合はエラーになるため、事前に `git worktree list` で確認する。
- worktreeの削除(`git worktree remove`)はこのスキルの対象外。ユーザーから明示的に依頼された場合のみ別途対応する。
