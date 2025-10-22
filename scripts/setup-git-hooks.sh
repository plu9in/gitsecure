#!/bin/bash
# scripts/setup-git-hooks.sh
# Installation modulaire des hooks Git avec cible personnalisable

set -e

# Configuration
DEFAULT_TARGET_REPO="."  # Dépôt courant par défaut
HOOKS_SOURCE_DIR="$(dirname "$0")/git-hooks"

# Fonction d'affichage d'aide
show_help() {
    cat << EOF
🔧 Git Hooks Installer - Vault Security

Usage: $0 [OPTIONS] [TARGET_REPO]

Install security git hooks to prevent committing sensitive files.

Arguments:
  TARGET_REPO    Target Git repository path (default: current directory)

Options:
  -h, --help     Show this help message
  -l, --list     List available hooks
  -s, --source   Specify custom hooks source directory
  --force        Force installation even if hooks exist

Examples:
  $0                          # Install in current repo
  $0 /path/to/my/repo         # Install in specific repo
  $0 --list                   # List available hooks
  $0 -s /custom/hooks ./repo  # Install from custom source

Available hooks:
  • pre-commit    - Blocks sensitive files (secrets, keys, tokens)
  • pre-push      - Security history scan before push
  • commit-msg    - Commit message format validation
EOF
}

# Fonction pour lister les hooks disponibles
list_hooks() {
    local source_dir="${1:-$HOOKS_SOURCE_DIR}"
    
    if [ ! -d "$source_dir" ]; then
        echo "❌ Hooks source directory not found: $source_dir"
        return 1
    fi
    
    echo "📋 Available hooks in $source_dir:"
    for hook_file in "$source_dir"/*; do
        if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            echo "  ✅ $hook_name (executable)"
        elif [ -f "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            echo "  📄 $hook_name (needs chmod +x)"
        fi
    done
}

# Parse des arguments
TARGET_REPO="$DEFAULT_TARGET_REPO"
CUSTOM_SOURCE_DIR=""
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_hooks
            exit 0
            ;;
        -s|--source)
            CUSTOM_SOURCE_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        -*)
            echo "❌ Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            TARGET_REPO="$1"
            shift
            ;;
    esac
done

# Déterminer le répertoire source des hooks
if [ -n "$CUSTOM_SOURCE_DIR" ]; then
    HOOKS_SOURCE_DIR="$CUSTOM_SOURCE_DIR"
fi

# Vérifications
echo "🔧 Git Hooks Installer"
echo "======================"

# Vérifier le dépôt cible
if [ ! -d "$TARGET_REPO/.git" ]; then
    echo "❌ Error: Not a Git repository: $TARGET_REPO"
    echo "   Please specify a valid Git repository path"
    exit 1
fi

# Vérifier le répertoire source des hooks
if [ ! -d "$HOOKS_SOURCE_DIR" ]; then
    echo "❌ Error: Hooks source directory not found: $HOOKS_SOURCE_DIR"
    echo "   Available options:"
    echo "   1. Run from Vault project root (contains scripts/git-hooks/)"
    echo "   2. Use -s/--source to specify custom hooks directory"
    echo "   3. Run './scripts/create-git-hooks-templates.sh' first"
    exit 1
fi

HOOKS_DIR="$TARGET_REPO/.git/hooks"

# Backup des hooks existants
backup_existing_hooks() {
    local backup_dir="$TARGET_REPO/.git-hooks-backup/$(date +%Y%m%d_%H%M%S)"
    
    if ls "$HOOKS_DIR"/* >/dev/null 2>&1; then
        mkdir -p "$backup_dir"
        cp -r "$HOOKS_DIR"/* "$backup_dir/" 2>/dev/null || true
        echo "✅ Existing hooks backed up to: $backup_dir"
        return 0
    else
        echo "ℹ️  No existing hooks to backup"
        return 1
    fi
}

# Fonction pour installer un hook
install_hook() {
    local hook_name="$1"
    local source_file="$HOOKS_SOURCE_DIR/$hook_name"
    local dest_file="$HOOKS_DIR/$hook_name"
    
    if [ ! -f "$source_file" ]; then
        echo "⚠️  Hook source file not found: $source_file"
        return 1
    fi
    
    # Vérifier si le hook existe déjà
    if [ -f "$dest_file" ] && [ "$FORCE_INSTALL" != "true" ]; then
        echo "⚠️  Hook already exists: $hook_name (use --force to overwrite)"
        return 2
    fi
    
    echo "📝 Installing $hook_name hook..."
    cp "$source_file" "$dest_file"
    chmod +x "$dest_file"
    
    # Vérification
    if [ -x "$dest_file" ]; then
        echo "✅ $hook_name hook installed successfully"
        return 0
    else
        echo "❌ Failed to install $hook_name hook"
        return 1
    fi
}

# Installation principale
echo ""
echo "🎯 Target repository: $(realpath "$TARGET_REPO")"
echo "📦 Hooks source: $(realpath "$HOOKS_SOURCE_DIR")"
echo ""

# Backup des hooks existants
if [ "$FORCE_INSTALL" = "true" ]; then
    backup_existing_hooks
fi

# Installation de tous les hooks disponibles
echo "📦 Installing available hooks..."

HOOKS_INSTALLED=0
HOOKS_SKIPPED=0
HOOKS_FAILED=0

for hook_file in "$HOOKS_SOURCE_DIR"/*; do
    if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
        hook_name=$(basename "$hook_file")
        case $(install_hook "$hook_name") in
            0) HOOKS_INSTALLED=$((HOOKS_INSTALLED + 1)) ;;
            1) HOOKS_FAILED=$((HOOKS_FAILED + 1)) ;;
            2) HOOKS_SKIPPED=$((HOOKS_SKIPPED + 1)) ;;
        esac
    elif [ -f "$hook_file" ]; then
        hook_name=$(basename "$hook_file")
        echo "⚠️  Hook not executable: $hook_name (run: chmod +x '$hook_file')"
        HOOKS_FAILED=$((HOOKS_FAILED + 1))
    fi
done

# Résumé
echo ""
echo "📊 Installation summary:"
echo "   ✅ Hooks installed: $HOOKS_INSTALLED"
if [ $HOOKS_SKIPPED -gt 0 ]; then
    echo "   ⚠️  Hooks skipped: $HOOKS_SKIPPED (use --force to overwrite)"
fi
if [ $HOOKS_FAILED -gt 0 ]; then
    echo "   ❌ Hooks failed: $HOOKS_FAILED"
fi

if [ $HOOKS_INSTALLED -gt 0 ]; then
    echo ""
    echo "🎉 Git hooks installation completed!"
    echo ""
    echo "📋 Installed hooks:"
    for hook_file in "$HOOKS_SOURCE_DIR"/*; do
        if [ -f "$hook_file" ] && [ -x "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            if [ -x "$HOOKS_DIR/$hook_name" ]; then
                echo "   • $hook_name ✅"
            else
                echo "   • $hook_name ❌"
            fi
        fi
    done
    echo ""
    echo "💡 Usage tips:"
    echo "   Normal workflow: git commit && git push"
    echo "   Bypass hooks:    git commit --no-verify"
    echo "   Update hooks:    $0 --force $TARGET_REPO"
    echo ""
    echo "🔒 Security features:"
    echo "   • Blocks commits of secrets, keys, certificates"
    echo "   • Scans for sensitive patterns in code"
    echo "   • Validates commit message format"
else
    echo "❌ No hooks were installed successfully."
    exit 1
fi