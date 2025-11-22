#!/bin/bash

# sync_upstream.sh
# Syncs the local repository with the upstream repository, resetting the main branch.
# Implements self-preservation logic to backup itself and handle gitignore.

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Self-Preservation Start ---
SCRIPT_NAME=$(basename "$0")
PS_SCRIPT_NAME="sync_upstream.ps1"
TEMP_DIR=$(mktemp -d)
BACKUP_SCRIPT="$TEMP_DIR/$SCRIPT_NAME"
BACKUP_PS_SCRIPT="$TEMP_DIR/$PS_SCRIPT_NAME"

log_info "Starting self-preservation..."

# Backup scripts
if [ -f "$0" ]; then
    cp "$0" "$BACKUP_SCRIPT"
    log_info "Backed up $SCRIPT_NAME to $BACKUP_SCRIPT"
fi

if [ -f "$PS_SCRIPT_NAME" ]; then
    cp "$PS_SCRIPT_NAME" "$BACKUP_PS_SCRIPT"
    log_info "Backed up $PS_SCRIPT_NAME to $BACKUP_PS_SCRIPT"
fi

# Ensure .gitignore includes scripts
ensure_gitignore() {
    local file=$1
    if ! grep -q "^$file$" .gitignore; then
        log_info "Adding $file to .gitignore"
        echo "$file" >> .gitignore
    else
        log_info "$file already in .gitignore"
    fi
}

ensure_gitignore "$SCRIPT_NAME"
ensure_gitignore "$PS_SCRIPT_NAME"

# Unstage scripts if tracked
if git ls-files --error-unmatch "$SCRIPT_NAME" > /dev/null 2>&1; then
    log_warn "Unstaging $SCRIPT_NAME"
    git rm --cached "$SCRIPT_NAME"
fi

if git ls-files --error-unmatch "$PS_SCRIPT_NAME" > /dev/null 2>&1; then
    log_warn "Unstaging $PS_SCRIPT_NAME"
    git rm --cached "$PS_SCRIPT_NAME"
fi
# --- Self-Preservation End ---

# Fetch upstream
log_info "Fetching upstream..."
if ! git remote get-url upstream > /dev/null 2>&1; then
    log_error "Remote 'upstream' not found. Please add it with 'git remote add upstream <url>'."
    exit 1
fi
git fetch upstream

# Determine main branch
if git show-ref --verify --quiet refs/remotes/upstream/main; then
    MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/remotes/upstream/master; then
    MAIN_BRANCH="master"
else
    log_error "Could not detect 'main' or 'master' branch on upstream."
    exit 1
fi

log_info "Detected main branch: $MAIN_BRANCH"

# Switch to main branch locally
if git show-ref --verify --quiet refs/heads/$MAIN_BRANCH; then
    log_info "Switching to local $MAIN_BRANCH..."
    git checkout $MAIN_BRANCH
else
    log_info "Creating local $MAIN_BRANCH from upstream/$MAIN_BRANCH..."
    git checkout -b $MAIN_BRANCH upstream/$MAIN_BRANCH
fi

# Reset to upstream
log_info "Resetting $MAIN_BRANCH to upstream/$MAIN_BRANCH..."
git reset --hard upstream/$MAIN_BRANCH

# Delete other local branches
log_info "Cleaning up other local branches..."
# List all branches, exclude the current one (main/master), and delete them.
# sed 's/^[ *]*//' removes the asterisk and spaces from 'git branch' output
git branch | grep -v "^[ *]*$MAIN_BRANCH$" | while read -r branch; do
    branch=$(echo "$branch" | sed 's/^[ *]*//')
    if [ -n "$branch" ]; then
        log_info "Deleting branch: $branch"
        git branch -D "$branch"
    fi
done

# --- Restoration Start ---
log_info "Restoring scripts from backup..."
if [ -f "$BACKUP_SCRIPT" ]; then
    cp "$BACKUP_SCRIPT" "$SCRIPT_NAME"
    chmod +x "$SCRIPT_NAME"
    log_info "Restored $SCRIPT_NAME"
fi

if [ -f "$BACKUP_PS_SCRIPT" ]; then
    cp "$BACKUP_PS_SCRIPT" "$PS_SCRIPT_NAME"
    log_info "Restored $PS_SCRIPT_NAME"
fi

# Re-apply gitignore check (since reset --hard might have reverted .gitignore)
ensure_gitignore "$SCRIPT_NAME"
ensure_gitignore "$PS_SCRIPT_NAME"

# Remove temp dir
rm -rf "$TEMP_DIR"
# --- Restoration End ---

log_info "Sync complete! You are now on $MAIN_BRANCH, identical to upstream/$MAIN_BRANCH."