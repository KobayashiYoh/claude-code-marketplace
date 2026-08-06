"""
会計年度と四半期を計算するスクリプト。
会計年度は10月起点。年度名はその会計年度が終わる年（9月が属する年）。

四半期の区分:
  Q1: 10月〜12月
  Q2: 1月〜3月
  Q3: 4月〜6月
  Q4: 7月〜9月

例:
  2025年12月 → FY2026_Q1
  2026年1月  → FY2026_Q2
  2026年4月  → FY2026_Q3
  2026年7月  → FY2026_Q4
"""

from datetime import date

today = date.today()
m, y = today.month, today.year

fy = y + 1 if m >= 10 else y

if m >= 10:
    q = 1
elif m <= 3:
    q = 2
elif m <= 6:
    q = 3
else:
    q = 4

print(f"FY{fy}_Q{q}")
