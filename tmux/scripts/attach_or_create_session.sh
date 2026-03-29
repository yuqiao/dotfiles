#!/bin/bash
# 用于替代 tmux new-session -A -s <name>
# 支持带索引前缀的 session 名称匹配（如 1-dev 匹配 dev）

label="${1:-session}"

if [[ -z "$label" ]]; then
    exit 1
fi

# 查找匹配的 session（支持 {index}-{label} 格式）
matching_session=$(tmux list-sessions -F '#{session_id} #{session_name}' 2>/dev/null | \
    while read -r sid name; do
        # 精确匹配
        if [[ "$name" == "$label" ]]; then
            echo "$sid"
            break
        fi
        # 索引前缀匹配：{index}-{label}
        if [[ "$name" =~ ^[0-9]+-(.+)$ ]]; then
            extracted_label="${BASH_REMATCH[1]}"
            if [[ "$extracted_label" == "$label" ]]; then
                echo "$sid"
                break
            fi
        fi
    done)

if [[ -n "$matching_session" ]]; then
    # 找到匹配的 session，attach 到它
    tmux switch-client -t "$matching_session" 2>/dev/null || \
        tmux attach-session -t "$matching_session" 2>/dev/null
else
    # 没找到，创建新 session
    # 使用临时名称，让 session_manager.py 来分配正确的索引前缀
    session_id=$(tmux new-session -d -P -s "$label" -F '#{session_id}' 2>/dev/null)
    if [[ -n "$session_id" ]]; then
        # 触发 session_manager 确保编号正确
        python3 "$HOME/.config/tmux/scripts/session_manager.py" ensure 2>/dev/null
        tmux switch-client -t "$session_id" 2>/dev/null || \
            tmux attach-session -t "$session_id" 2>/dev/null
    fi
fi