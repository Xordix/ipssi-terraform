# Corrigé — TP02 bis : VPC via module registry

Projet Terraform **prêt à lancer** qui crée le **même VPC que le TP02 custom**, mais via le module officiel [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).

Objectif pédagogique : comparer 25 lignes de code registry vs ~150 lignes custom.

## Différence avec `tp02-vpc-complet/`

| | Custom | Registry |
|---|---|---|
| Lignes `main.tf` | ~170 | ~30 |
| Compréhension nécessaire | Forte | Connaissance du module |
| Nombre de ressources créées | 17 | ~17 (via le module) |
| Tags fins par subnet | Trivial | `public_subnet_tags` / `private_subnet_tags` |
| VPC Flow Logs | À coder | `enable_flow_log = true` |
| NAT par AZ | À coder (boucle) | `single_nat_gateway = false` |

🟡 **CIDR différent** : ce corrigé utilise `10.1.0.0/16` (vs `10.0.0.0/16` pour le TP02 custom) pour permettre de faire tourner les deux en parallèle sans collision.

## Ressources créées par le module

Le module crée en arrière-plan les mêmes ressources que le TP02 custom :

- 1 `aws_vpc`
- 1 `aws_internet_gateway`
- 4 `aws_subnet` (2 publics + 2 privés)
- 1 `aws_eip` (pour le NAT)
- 1 `aws_nat_gateway`
- 4 `aws_route_table` (ou 3, selon options)
- 4+ `aws_route_table_association`
- Tags propagés

## Prérequis

Mêmes que le TP02 custom. Le module est téléchargé automatiquement par `terraform init`.

## 🟡 Coût AWS

**~35 €/mois** tant que le NAT Gateway tourne. **Destroy obligatoire** en fin de TP.

## Lancer

```bash
cd corriges/jour2/tp02-vpc-registry

export AWS_PROFILE=formation

terraform init
# Telecharge le module terraform-aws-modules/vpc/aws

terraform fmt
terraform validate
terraform plan
# ~17 ressources a creer (dependant des options du module)

terraform apply -auto-approve
```

## Résultat attendu (extrait)

```text
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

internet_gateway_id   = "igw-0987654321fedcba"
nat_gateway_public_ips = tolist([
  "52.49.xxx.xxx",
])
private_subnet_ids    = tolist([
  "subnet-0aaa...",
  "subnet-0bbb...",
])
public_subnet_ids     = tolist([
  "subnet-0ccc...",
  "subnet-0ddd...",
])
vpc_cidr              = "10.1.0.0/16"
vpc_id                = "vpc-0987654321fedcba"
```

## Comparer avec le TP02 custom

```bash
# Depuis la racine du repo
diff -r --brief corriges/jour2/tp02-vpc-complet/ corriges/jour2/tp02-vpc-registry/

# Compter les lignes de main.tf
wc -l corriges/jour2/tp02-vpc-complet/main.tf \
      corriges/jour2/tp02-vpc-registry/main.tf
```

Vous devez voir un ratio d'environ 5x moins de lignes pour la version registry.

## Nettoyage OBLIGATOIRE

```bash
terraform destroy -auto-approve
```

## En production

Le module registry est le choix **par défaut** en production :

- ✅ Pinner la version exacte : `version = "5.5.1"` (pas `~> 5.5`)
- ✅ Activer les VPC Flow Logs : `enable_flow_log = true`
- ✅ NAT par AZ : `single_nat_gateway = false`
- ✅ VPC endpoints : `enable_s3_endpoint = true`, `enable_dynamodb_endpoint = true`
- ✅ Lire les release notes avant chaque bump de version
- ✅ Tester en dev avant de bumper en prod
