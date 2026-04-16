# Corrigé — TP01 : bucket S3 sécurisé

Projet Terraform **prêt à lancer** qui provisionne un bucket S3 **production-ready** avec toutes les bonnes pratiques de sécurité AWS.

## Ce qui est créé

| Ressource | Rôle |
|---|---|
| `random_pet.suffix` | Suffixe aléatoire pour le nom unique |
| `aws_s3_bucket.main` | Bucket S3 |
| `aws_s3_bucket_versioning.main` | Versioning activé |
| `aws_s3_bucket_server_side_encryption_configuration.main` | Chiffrement SSE-S3 (AES256) |
| `aws_s3_bucket_public_access_block.main` | Block Public Access (4 options) |
| `aws_s3_bucket_policy.main` | Refus explicite des requêtes non-HTTPS |

**Total** : 6 ressources créées.

## Sécurité appliquée

- 🟢 Versioning activé (protection suppression/écrasement)
- 🟢 Chiffrement au repos (AES256 SSE-S3)
- 🟢 Block Public Access sur les 4 options
- 🟢 Refus explicite de toute requête non-HTTPS via bucket policy
- 🟢 Tags normalisés (Project, Environment, Owner, CostCenter, ManagedBy)

## Prérequis

- Terraform ≥ 1.7.0
- AWS CLI v2 avec profil configuré
- TFLint (optionnel, pour `tflint --init` et lint)
- Droits IAM : `s3:*` sur le bucket à créer, `sts:GetCallerIdentity`

## Lancer le projet

```bash
cd corriges/jour1/tp01-bucket-s3-securise

# 1. Profil AWS
export AWS_PROFILE=formation

# 2. Renseigner votre email owner (obligatoire)
cp terraform.tfvars.example terraform.tfvars
# Editer terraform.tfvars et remplacer votre-email@example.com

# 3. Init (telecharge aws + random)
terraform init

# 4. (optionnel) Init du plugin tflint AWS
tflint --init

# 5. Valider et linter
terraform fmt
terraform validate
tflint

# 6. Plan : doit annoncer 6 ressources a creer
terraform plan

# 7. Apply
terraform apply -auto-approve
```

## Résultat attendu

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn           = "arn:aws:s3:::formation-tp01-123456789012-quiet-fox"
bucket_name          = "formation-tp01-123456789012-quiet-fox"
bucket_region        = "eu-west-1"
encryption_algorithm = "AES256"
versioning_status    = "Enabled"
```

## Validation manuelle via AWS CLI

```bash
BUCKET=$(terraform output -raw bucket_name)

# 1. Bucket existe
aws s3api head-bucket --bucket "$BUCKET"

# 2. Versioning
aws s3api get-bucket-versioning --bucket "$BUCKET"
# Attendu : { "Status": "Enabled" }

# 3. Chiffrement
aws s3api get-bucket-encryption --bucket "$BUCKET"
# Attendu : SSEAlgorithm: AES256

# 4. Block Public Access
aws s3api get-public-access-block --bucket "$BUCKET"
# Attendu : les 4 options a true

# 5. Bucket policy
aws s3api get-bucket-policy --bucket "$BUCKET" | jq -r .Policy | jq .
# Attendu : Deny sur aws:SecureTransport false

# 6. Tags
aws s3api get-bucket-tagging --bucket "$BUCKET"
# Attendu : Project, Environment, Owner, ManagedBy, CostCenter

# 7. Test refus HTTP (attendu : 403)
curl -v "http://$BUCKET.s3.amazonaws.com/"
```

## Nettoyage (OBLIGATOIRE)

```bash
terraform destroy -auto-approve
```

Si le destroy échoue avec `BucketNotEmpty` :

```bash
# Lister et vider le bucket (y compris les versions)
aws s3api delete-objects \
  --bucket "$BUCKET" \
  --delete "$(aws s3api list-object-versions \
    --bucket "$BUCKET" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Puis re-lancer destroy
terraform destroy -auto-approve
```

## Troubleshooting

| Erreur | Cause | Fix |
|---|---|---|
| `owner doit etre une adresse email valide` | `terraform.tfvars` non rempli ou email invalide | Éditer `terraform.tfvars` |
| `BucketAlreadyExists` | Collision de nom (très rare avec random_pet) | Re-lancer `terraform apply` |
| `AccessDenied applying policy` | Ordre d'application policy/PAB incorrect | Le `depends_on` est dans le code, vérifiez qu'il n'a pas été supprimé |
| `InvalidRequest: The bucket does not allow ACLs` | Vous avez ajouté `acl = "private"` sur `aws_s3_bucket` | Les ACL sont dépréciées, ne pas les utiliser |
| `BucketNotEmpty` au destroy | Objets présents | Voir section nettoyage ci-dessus |

## En production, à ajouter

- **SSE-KMS** avec une CMK dédiée (audit + rotation)
- **Lifecycle policy** (transition Glacier, expiration versions)
- **Logging d'accès** vers un bucket séparé
- **Réplication cross-région** pour la DR
- **VPC endpoint S3** si accès depuis EC2
- **CloudTrail data events** pour audit fin
