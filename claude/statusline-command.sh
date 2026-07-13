#!/bin/sh
input=$(cat)

# Forest-green palette (truecolor ANSI, real ESC byte)
esc=$(printf '\033')
G_BRIGHT="${esc}[1;38;2;46;160;46m"  # bright bold green - dir, model
G="${esc}[38;2;34;139;34m"           # forest green #228B22 - branch, time
G_DIM="${esc}[38;2;120;150;120m"     # muted green - usage stats
R="${esc}[0m"

# One jq pass, one value per line - empty lines preserve empty/missing fields
{
  read -r cwd
  read -r model
  read -r ctx
  read -r r5
  read -r r7
  read -r added
  read -r removed
} <<EOF
$(printf '%s' "$input" | jq -r '
  .cwd,
  (.model.display_name // ""),
  (.context_window.used_percentage // ""),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0)
')
EOF

short_cwd=$(printf '%s' "$cwd" | sed "s|^$HOME|~|")
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
now=$(date +"%l:%M %p" | sed 's/^ *//')

out="${G_BRIGHT}${short_cwd}${R}"
[ -n "$branch" ] && out="${out} ${G}[${branch}]${R}"
[ -n "$model" ]  && out="${out}  ${G_BRIGHT}${model}${R}"
out="${out}  ${G}${now}${R}"
[ -n "$ctx" ] && out="${out}  ${G_DIM}$(printf '%.0f' "$ctx")% ctx${R}"
if [ -n "$r5" ] || [ -n "$r7" ]; then
  rl=""
  [ -n "$r5" ] && rl="5h $(printf '%.0f' "$r5")%"
  [ -n "$r7" ] && { [ -n "$rl" ] && rl="${rl} · "; rl="${rl}7d $(printf '%.0f' "$r7")%"; }
  out="${out}  ${G_DIM}${rl}${R}"
fi
if [ "${added:-0}" != "0" ] || [ "${removed:-0}" != "0" ]; then
  out="${out}  ${G_DIM}+${added} -${removed}${R}"
fi

printf '%s' "$out"
