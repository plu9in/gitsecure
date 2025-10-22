#!/bin/bash
# install-git-hooks-universal.sh
# Script universel d'installation des hooks de sécurité Git

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_SOURCE_DIR="$SCRIPT_DIR/scripts/git-hooks"

show_banner() {
    cat << 'EOF'
    
    ███████╗██╗ ██████╗    ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
    ██╔════╝██║██╔════╝    ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
    █████╗  ██║██║         ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝ 
    ██╔══╝  ██║██║         ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝  
    ██║     ██║╚██████╗    ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║   
    ╚═╝     ╚═╝ ╚═════╝    ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝   
                                                                                          
    🔒 Git Security Hooks Installer
EOF
}

main() {
    show_banner
    
    # Vérifier si les hooks sources existent
    if [ ! -d "$HOOKS_SOURCE_DIR" ]; then
        echo "❌ Hooks not found. Creating templates..."
        "$SCRIPT_DIR/scripts/create-git-hooks-templates.sh"
    fi
    
    # Demander le dépôt cible
    echo ""
    echo "🎯 Target Git repository installation"
    echo "====================================="
    
    if [ $# -eq 0 ]; then
        read -p "Enter target repository path [current]: " target_repo
        target_repo="${target_repo:-.}"
    else
        target_repo="$1"
    fi
    
    # Installation
    echo ""
    "$SCRIPT_DIR/scripts/setup-git-hooks.sh" "$target_repo"
    
    # Message de succès
    echo ""
    echo "💡 Pro tip: You can use this installer on any Git repository:"
    echo "   $0 /path/to/your/repo"
    echo ""
    echo "📚 More options: ./scripts/setup-git-hooks.sh --help"
}

main "$@"