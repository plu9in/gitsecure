#!/bin/bash
# scripts/create-git-hooks-templates.sh
# Crée les templates des hooks Git dans le dossier source

set -e

show_help() {
    cat << EOF
📝 Git Hooks Templates Creator

Usage: $0 [TARGET_DIR]

Create security git hooks templates in specified directory.

Arguments:
  TARGET_DIR    Target directory for hooks (default: scripts/git-hooks)

Examples:
  $0                          # Create in scripts/git-hooks
  $0 /path/to/hooks           # Create in custom directory
  $0 .                        # Create in current directory
EOF
}

# Déterminer le répertoire cible
TARGET_DIR="${1:-scripts/git-hooks}"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

echo "📁 Creating Git hooks templates in: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "📝 Generating hook templates..."

# Création du pre-commit hook
cat > "$TARGET_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Git Pre-commit Hook - Security Scanner
# Blocks commits of sensitive files and secrets

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Scanning for sensitive files..."

# Fichiers interdits
FORBIDDEN_PATTERNS=(
    "*.key"
    "*.token"
    "*.crt"
    "*.pem"
    "*.p12"
    "*.pfx"
    "unseal_keys*"
    "root_token*"
    ".env"
    "secrets/*"
    "backups/*"
)

# Mots-clés sensibles
SENSITIVE_KEYWORDS=(
    "password.*="
    "token.*="
    "secret.*="
    "key.*="
    "unseal.*key"
    "root.*token"
    "BEGIN.*PRIVATE.*KEY"
    "BEGIN.*RSA.*PRIVATE.*KEY"
    "BEGIN.*CERTIFICATE"
)

ERRORS=0

# Scan des noms de fichiers
for file in $(git diff --cached --name-only); do
    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        if [[ "$file" == $pattern ]]; then
            echo -e "${RED}❌ COMMIT REJECTED:${NC} Sensitive file: $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
done

# Scan du contenu
for file in $(git diff --cached --name-only); do
    if git diff --cached "$file" | grep -q "Binary files"; then
        continue
    fi
    
    for keyword in "${SENSITIVE_KEYWORDS[@]}"; do
        if git diff --cached "$file" | grep -i -E "$keyword" > /dev/null; then
            echo -e "${RED}❌ COMMIT REJECTED:${NC} Sensitive content in: $file"
            echo -e "   Pattern: $keyword"
            ERRORS=$((ERRORS + 1))
        fi
    done
done

# Vérification des fichiers .env
ENV_FILES=$(git diff --cached --name-only | grep "\.env" | grep -v "\.env.example")
if [ -n "$ENV_FILES" ]; then
    echo -e "${RED}❌ COMMIT REJECTED:${NC} .env files: $ENV_FILES"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo -e "\n${RED}🚫 Commit blocked! $ERRORS security issue(s) found.${NC}"
    echo -e "Use: ${YELLOW}git commit --no-verify${NC} to bypass (not recommended)"
    exit 1
else
    echo -e "${GREEN}✅ No sensitive files detected.${NC}"
fi

exit 0
EOF

# Création du pre-push hook
cat > "$TARGET_DIR/pre-push" << 'EOF'
#!/bin/bash
# Git Pre-push Hook - Security History Scanner
# Checks recent commits for sensitive files

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "🔒 Pre-push security scan..."

# Vérifier l'historique récent
RECENT_COMMITS=10
SENSITIVE_FILES=$(git log --oneline -n $RECENT_COMMITS --name-only --pretty=format: | sort | uniq | grep -E '\.(key|token|crt|pem|env)$' | grep -v ".env.example")

if [ -n "$SENSITIVE_FILES" ]; then
    echo -e "${RED}🚫 PUSH BLOCKED:${NC} Sensitive files in recent commits:"
    echo "$SENSITIVE_FILES"
    echo -e "\nTo fix:"
    echo "1. Remove from history: git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch FILENAME'"
    echo "2. Force push: git push --force"
    exit 1
fi

echo -e "${GREEN}✅ Security scan passed.${NC}"
exit 0
EOF

# Création du commit-msg hook
cat > "$TARGET_DIR/commit-msg" << 'EOF'
#!/bin/bash
# Git Commit-msg Hook - Message Validator
# Ensures proper commit message format

MSG_FILE=$1
COMMIT_MSG=$(cat "$MSG_FILE")

# Longueur minimale
if [ ${#COMMIT_MSG} -lt 10 ]; then
    echo "❌ Commit message too short. Minimum 10 characters required."
    exit 1
fi

# Format conventionnel recommandé
if ! echo "$COMMIT_MSG" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert): "; then
    echo "⚠️  Consider using: <type>: <description>"
    echo "   Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
fi
EOF

# Rendre les hooks exécutables
chmod +x "$TARGET_DIR"/*

echo "✅ Git hooks templates created in: $(realpath "$TARGET_DIR")"
echo ""
echo "📋 Created hooks:"
echo "   • pre-commit    - Security file scanner"
echo "   • pre-push      - History security check" 
echo "   • commit-msg    - Message format validator"
echo ""
echo "🚀 Install with: $0 [target_repo]"