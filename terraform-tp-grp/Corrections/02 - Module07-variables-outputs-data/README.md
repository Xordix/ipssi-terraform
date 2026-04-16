# Corrigé — Module 07 : variables, outputs, data sources

Projet Terraform **prêt à lancer** qui reprend le bucket S3 du TP01 et le rend entièrement paramétrable via variables, locals et data sources.

Objectif pédagogique : illustrer `variable`, `local`, `data source` sur un cas concret, et comprendre la précédence des sources de variables.

## Ressources créées

| Ressource | Rôle |
|---|---|
| `random_pet.suffix` | Suffixe aléatoire |
| `aws_s3_bucket.main` | Bucket S3 avec nom dérivé des variables |
| `aws_s3_bucket_public_access_block.main` | Block Public Access (sécurité minimale) |

**Total** : 3 ressources.

## Concepts illustrés

- 🟢 **Variables typées** avec `string`, `map(string)`
- 🟢 **Validation** (regex email, `contains()`)
- 🟢 **Locals** pour factoriser (`name_prefix`, `account_id`, `region`)
- 🟢 **Data sources** (`aws_caller_identity`, `aws_region`)
- 🟢 **`merge()`** pour combiner les default_tags et les tags utilisateur
- 🟢 **Output `tags_all`** pour voir tous les tags effectivement appliqués

## Prérequis

- Terraform ≥ 1.7.0
- AWS CLI v2 + profil configuré

## Lancer le projet

```bash
cd corriges/jour2/module07-variables-outputs-data

export AWS_PROFILE=formation

# Renseigner la variable obligatoire 'owner'
cp terraform.tfvars.example terraform.tfvars
# Editer terraform.tfvars pour mettre votre email

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
```

## Essayer la précédence

```bash
# 1. Via terraform.tfvars (priorite basse)
terraform apply -auto-approve

# 2. Via -var (prime sur tfvars)
terraform apply -auto-approve -var "environment=staging"

# 3. Via variable d'environnement TF_VAR_*
export TF_VAR_environment=prod
terraform apply -auto-approve

# Nettoyer la variable d env quand fini
unset TF_VAR_environment
```

Chaque appel montre que la source la plus prioritaire gagne (ligne de commande > env > tfvars > default).

## Résultat attendu

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

account_id   = "123456789012"
bucket_arn   = "arn:aws:s3:::formation-terraform-dev-123456789012-quiet-fox"
bucket_name  = "formation-terraform-dev-123456789012-quiet-fox"
name_prefix  = "formation-terraform-dev"
region       = "eu-west-1"
tags_applied = tomap({
  "CostCenter"  = "formation"
  "Environment" = "dev"
  "ManagedBy"   = "Terraform"
  "Module"      = "07-variables-outputs-data"
  "Name"        = "formation-terraform-dev-bucket"
  "Owner"       = "votre-email@example.com"
  "Project"     = "formation-terraform"
})
```

## Nettoyage

```bash
terraform destroy -auto-approve
```
