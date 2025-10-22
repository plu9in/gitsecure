#!/bin/bash
# setup-project.sh
# Script d'installation complet du projet Vault + Consul

set -e

echo "🚀 Setting up Vault + Consul production environment..."
echo "====================================================="

# Vérification des prérequis
echo "📋 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    exit 1
fi

echo "✅ All prerequisites met."

# Création de la structure de répertoires
echo "📁 Creating directory structure..."
mkdir -p \
    secrets/tls/vault \
    secrets/tls/consul \
    secrets/tls/haproxy \
    secrets/tokens \
    secrets/keys \
    volumes/vault/data \
    volumes/vault/logs \
    volumes/vault/audit \
    volumes/consul/data \
    backups/vault \
    backups/consul \
    backups/config \
    scripts/vault \
    scripts/consul \
    scripts/backup \
    scripts/security \
    scripts/tls \
    config/haproxy

echo "✅ Directory structure created."

# Copie des scripts (supposant qu'ils sont dans le même répertoire)
echo "📦 Installing scripts..."

# Rendre les scripts exécutables
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x scripts/vault/*.sh 2>/dev/null || true
chmod +x scripts/consul/*.sh 2>/dev/null || true
chmod +x scripts/backup/*.sh 2>/dev/null || true
chmod +x scripts/security/*.sh 2>/dev/null || true
chmod +x scripts/tls/*.sh 2>/dev/null || true

echo "✅ Scripts installed and made executable."

# Installation des hooks Git
echo "🔧 Installing Git hooks..."
if [ -d ".git" ]; then
    ./scripts/setup-git-hooks.sh
else
    echo "⚠️  Not a Git repository. Skipping Git hooks installation."
    echo "   To initialize Git: git init"
fi

# Création des fichiers de configuration de base
echo "📝 Creating configuration files..."

# Fichier .env.example
cat > .env.example << 'EOF'
# Configuration Vault + Consul
# Copy to .env and update with your values

# Versioning
VAULT_VERSION=1.15.0
CONSUL_VERSION=1.16.0

# Network
DOMAIN=company.com
VAULT_API_ADDR=https://vault.company.com:8200
CONSUL_HTTP_ADDR=https://consul.company.com:8500

# Security
VAULT_DISABLE_MLOCK=false
CONSUL_ACL_DEFAULT_POLICY=deny

# Backup
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION_KEY_ID=backup@company.com

# TLS (set to false for development)
TLS_ENABLED=true
EOF

# Fichier README sécurité
cat > SECURITY.md << 'EOF'
# Security Policy

## Protected Files

The following file patterns are BLOCKED from being committed:
- secrets/ - All secrets directory
- *.key - Private keys  
- *.token - Authentication tokens
- *.crt, *.pem - Certificates (except public CA)
- .env - Environment files
- unseal_keys* - Vault unseal keys
- root_token* - Vault root tokens

## Git Hooks

This repository uses pre-commit hooks to prevent accidental commits of sensitive data.

### To install hooks:
```bash
./scripts/setup-git-hooks.sh