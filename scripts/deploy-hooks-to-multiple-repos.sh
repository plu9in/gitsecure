#!/bin/bash
# deploy-hooks-to-multiple-repos.sh
# Déploie les hooks de sécurité sur plusieurs dépôts

set -e

HOOKS_INSTALLER="./scripts/setup-git-hooks.sh"
REPOS=(
    "/path/to/repo1"
    "/path/to/repo2" 
    "/home/user/projects/api"
    "/home/user/projects/frontend"
)

echo "🚀 Deploying security hooks to multiple repositories..."
echo "======================================================"

for repo in "${REPOS[@]}"; do
    if [ -d "$repo/.git" ]; then
        echo ""
        echo "📦 Installing hooks in: $repo"
        echo "────────────────────────────────────────────────────"
        
        if "$HOOKS_INSTALLER" --force "$repo"; then
            echo "✅ Success: $repo"
        else
            echo "❌ Failed: $repo"
        fi
    else
        echo "⚠️  Skipping (not a Git repo): $repo"
    fi
done

echo ""
echo "🎉 Deployment completed!"