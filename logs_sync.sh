#!/bin/bash
# Watch logs directory for changes and sync repository via git.
# Usage: ./logs_sync.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
REPO_DIR="$SCRIPT_DIR"

SSH_KEY="$HOME/.ssh/id_ed25519_personal"

cd "$REPO_DIR" || exit 1

echo "🔍 Monitoring $LOG_DIR for changes..."

inotifywait -m -e close_write,create,delete,move "$LOG_DIR" |
while read -r path action file; do
    echo "📝 Change detected: $file ($action)"
    git add "$LOG_DIR"/*
    git commit -m "Sync logs: $(date '+%Y-%m-%d %H:%M:%S')" && \
    GIT_SSH_COMMAND="ssh -i $SSH_KEY" git push
done