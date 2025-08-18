#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_action() {
    echo -e "${PURPLE}🔄${NC} $1"
}

# Check branch naming convention
check_branch_name() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local branch_regex="^[a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+$|^(main|dev|develop)$"
    
    print_action "Checking branch name: $branch"
    
    if [[ $branch =~ $branch_regex ]]; then
        print_success "Branch name follows convention"
        return 0
    else
        print_warning "Branch name '$branch' doesn't follow convention ((discord-username)/feature-description)"
        print_info "Expected format: (discord-username)/feature-description or (discord-username)/bugfix-description"
        return 0  # Warning only, don't block
    fi
}

# Run type check, lint, format, knip
run_quality_checks() {
    print_action "Running quality checks..."
    
    print_info "Running TypeScript type check..."
    if ! pnpm type-check; then
        print_error "TypeScript type check failed"
        return 1
    fi
    print_success "TypeScript type check passed"
    
    print_info "Running ESLint..."
    # Get currently staged files
    local staged_files=$(git diff --name-only --cached --diff-filter=ACMR)
    
    if ! pnpm lint:fix; then
        print_error "ESLint check failed"
        return 1
    fi
    print_success "ESLint check passed"
    
    # Check if any staged files have unstaged changes after ESLint
    if [ -n "$staged_files" ]; then
        local eslint_changed_files=""
        while IFS= read -r file; do
            if [ -n "$(git diff "$file")" ]; then
                eslint_changed_files="$eslint_changed_files $file"
            fi
        done <<< "$staged_files"
        
        if [ -n "$eslint_changed_files" ] && [ "$eslint_changed_files" != " " ]; then
            print_info "Auto-staging ESLint fixes for:$eslint_changed_files"
            echo "$eslint_changed_files" | xargs git add
        fi
    fi
    
    print_info "Running code formatting..."
    # Get currently staged files
    local staged_files_format=$(git diff --name-only --cached --diff-filter=ACMR)

    if ! pnpm format; then
        print_error "Code formatting failed"
        return 1
    fi
    print_success "Code formatting check passed"
    
    # Check if any staged files have unstaged changes after formatting
    if [ -n "$staged_files_format" ]; then
        local format_changed_files=""
        while IFS= read -r file; do
            if [ -n "$(git diff "$file")" ]; then
                format_changed_files="$format_changed_files $file"
            fi
        done <<< "$staged_files_format"
        
        if [ -n "$format_changed_files" ] && [ "$format_changed_files" != " " ]; then
            print_info "Auto-staging formatting changes for:$format_changed_files"
            echo "$format_changed_files" | xargs git add
        fi
    fi
    
    print_info "Running Knip..."
    if ! pnpm knip; then
        print_error "Knip found issues"
    else
        print_success "Knip check passed"
    fi
    
    return 0
}

# Install dependencies from package.json
maybe_install_packages() {
    if pnpm install; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        return 1
    fi
    return 0
}

# Validate commit message
validate_commit_message() {
    local commit_msg="$1"
    local commit_regex='^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert): .{1,50}'
    
    print_action "Validating commit message..."
    
    # Check minimum length
    if [ ${#commit_msg} -lt 10 ]; then
        print_error "Commit message must be at least 10 characters long"
        return 1
    fi
    
    # Check format (warning only)
    if [[ ! $commit_msg =~ $commit_regex ]]; then
        print_warning "Commit message doesn't follow conventional format"
        print_info "Expected: 'type: description' where type is one of:"
        print_info "feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
        print_info "Example: 'feat: add user authentication'"
    else
        print_success "Commit message follows conventional format"
    fi
    
    return 0
}
