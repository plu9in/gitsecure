# Git Security Hooks - Vault & Consul

Système de hooks Git pour empêcher le commit accidentel de fichiers sensibles.

## Installation Rapide

Pour le projet courant:
```
./scripts/setup-git-hooks.sh
```

Pour un dépôt spécifique:
```
./scripts/setup-git-hooks.sh /chemin/vers/mon/depot
```

### Installation universelle:
```
./install-git-hooks-universal.sh
./install-git-hooks-universal.sh /chemin/vers/depot
```

## Hooks Disponibles

### pre-commit - Scan de sécurité:
- Fichiers sensibles: .key, .token, .crt, .pem, .env
- Mots-clés: password=, token=, secret=
- Clés privées: BEGIN PRIVATE KEY, BEGIN RSA PRIVATE KEY

### pre-push - Vérification historique:
- Vérifie les 10 derniers commits
- Détecte fichiers sensibles dans l'historique
- Bloque push si secrets détectés

### commit-msg - Validation messages:
- Longueur minimale: 10 caractères
- Format: type: description
- Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

## Utilisation Avancée

### Options:
```
./scripts/setup-git-hooks.sh --help
./scripts/setup-git-hooks.sh --list
./scripts/setup-git-hooks.sh --force /chemin/depot
./scripts/setup-git-hooks.sh -s /custom/hooks /chemin/depot
```

### Exemples:
```
./scripts/setup-git-hooks.sh
./scripts/setup-git-hooks.sh ~/projects/my-vault-config
./scripts/setup-git-hooks.sh --force ~/projects/consul-cluster
```

## Fichiers Bloqués

Extensions: `.key, .token, .crt, .pem, .p12, .pfx, .env`

Noms: `unseal_keys*, root_token*, secrets/*, backups/*`

Contenu: `password=*, token=*, secret=*, BEGIN PRIVATE KEY, BEGIN RSA PRIVATE KEY, BEGIN CERTIFICATE`

## Urgence

Contourner les hooks:
```
git commit --no-verify -m "Emergency fix"
git push --no-verify
```
Attention: le contournement doit être l'exception et non la règle.

Supprimer les hooks:
```
rm .git/hooks/pre-commit .git/hooks/pre-push .git/hooks/commit-msg
chmod -x .git/hooks/pre-commit .git/hooks/pre-push
```

Restaurer:
```
cp .git-hooks-backup/20240101_120000/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

## Structure

```
vault-consul-project/
├── scripts/
│   ├── setup-git-hooks.sh
│   ├── create-git-hooks-templates.sh
│   └── git-hooks/
│       ├── pre-commit
│       ├── pre-push
│       └── commit-msg
├── install-git-hooks-universal.sh
├── README.md
└── deploy-hooks-to-multiple-repos.sh
```

## Personnalisation

Créer les templates:
```
./scripts/create-git-hooks-templates.sh
```

Modifier patterns dans pre-commit:
```
FORBIDDEN_PATTERNS=(
    "*.key"
    "*.my-custom-extension"
    "secrets/*"
)

SENSITIVE_KEYWORDS=(
    "password.*="
    "my-custom-secret.*="
)
```

## Déploiement Multiple

Script deploy-hooks-to-multiple-repos.sh:
```
#!/bin/bash
REPOS=(
    "/path/to/repo1"
    "/path/to/repo2"
    "/path/to/repo3"
)
for repo in "${REPOS[@]}"; do
    ./scripts/setup-git-hooks.sh --force "$repo"
done
```

## Dépannage

Problèmes courants:
- "Not a Git repository": `git status, git init`
- "Hooks source directory not found": `./scripts/create-git-hooks-templates.sh`
- Hook non exécutable: `chmod +x scripts/git-hooks/*`

Debug:
```
bash -x ./scripts/setup-git-hooks.sh /chemin/depot
ls -la .git/hooks/
cat .git/hooks/pre-commit
```

## Mise à Jour des hooks

Mettre à jour:
```
./scripts/create-git-hooks-templates.sh
./scripts/setup-git-hooks.sh --force /chemin/depot
```

Vérifier:
```
ls -la .git/hooks/
diff .git/hooks/pre-commit scripts/git-hooks/pre-commit
```

## Bonnes Pratiques

Développeurs:
- Utiliser .env.example pour les templates
- Stocker les secrets dans Vault et les configurations dans Consul d'HashiCorp.
- Utiliser des tokens temporaires
- Valider le format des commits

Administrateurs:
- Déployer les hooks sur les dépôts sensibles
- Former les équipes
- Auditer l'historique de Git régulièrement
- Maintenir les hooks à jour

DevOps:
- Intégrer les hooks dans la CI/CD
- Automatiser le déploiement
- Monitorer les tentatives
- Documenter les procédures

## Contribution

Pour améliorer les hooks:
1. Forker le projet
2. Créer une branche feature (feat-)
3. Tester les modifications
4. Soumettre une pull request

Signaler un problème:
1. Vérifier si le problème a déjà été signalé
2. Créer un rapport avec les étapes de reproduction du problème
3. Inclure les messages d'erreur et l'environnement

## Licence

MIT 

Attention: Ces hooks sont une sécurité supplémentaire mais ne remplacent pas une bonne hygiène de développement.