# Corrigé — TP02 : VPC complet (custom)

Projet Terraform **prêt à lancer** qui crée un VPC AWS complet à 2 AZ **from scratch** (sans utiliser le module registry).

## Architecture créée

```text
VPC 10.0.0.0/16
├── IGW
├── Subnets publics : 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
├── Subnets privés  : 10.0.101.0/24 (AZ-a), 10.0.102.0/24 (AZ-b)
├── NAT Gateway single (dans public AZ-a) + EIP
├── Route table publique → IGW
├── Route table privée → NAT
└── Security Group bastion SSH
```

## Ressources créées (17 total)

| Type | Nombre |
|---|---|
| `aws_vpc` | 1 |
| `aws_internet_gateway` | 1 |
| `aws_subnet` (public) | 2 |
| `aws_subnet` (private) | 2 |
| `aws_eip` | 1 |
| `aws_nat_gateway` | 1 |
| `aws_route_table` | 2 |
| `aws_route_table_association` | 4 |
| `aws_security_group` | 1 |
| `aws_vpc_security_group_ingress_rule` | 1 |
| `aws_vpc_security_group_egress_rule` | 1 |
| **Total** | **17** |

## Prérequis

- Terraform ≥ 1.7.0
- AWS CLI v2 + profil configuré
- Quotas par défaut : 5 VPC, 5 NAT Gateway par AZ (largement suffisant)
- Droits IAM : `ec2:*` sur VPC/Subnet/IGW/NAT/RouteTable/SecurityGroup/EIP

## 🟡 Coût AWS

**~35 €/mois** tant que le NAT Gateway + EIP tournent. **Détruisez impérativement en fin de TP** (`terraform destroy`).

## Lancer le projet

```bash
cd corriges/jour2/tp02-vpc-complet

export AWS_PROFILE=formation

terraform init
terraform fmt
terraform validate
terraform plan
# Doit afficher : Plan: 17 to add, 0 to change, 0 to destroy.

terraform apply -auto-approve
# Creation : ~2-3 min (le NAT Gateway est lent)
```

## Résultat attendu

```text
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

bastion_security_group_id = "sg-0abc123def456"
internet_gateway_id       = "igw-0123456789abcdef"
nat_gateway_public_ip     = "52.49.123.45"
private_subnet_ids        = {
  "eu-west-1a" = "subnet-0aaa..."
  "eu-west-1b" = "subnet-0bbb..."
}
public_subnet_ids         = {
  "eu-west-1a" = "subnet-0ccc..."
  "eu-west-1b" = "subnet-0ddd..."
}
vpc_cidr                  = "10.0.0.0/16"
vpc_id                    = "vpc-0123456789abcdef"
```

## Validation manuelle

```bash
VPC_ID=$(terraform output -raw vpc_id)

# 1. VPC
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].[VpcId, CidrBlock, Tags[?Key==`Name`].Value | [0]]'

# 2. 4 subnets dans 2 AZ
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[].[SubnetId, AvailabilityZone, CidrBlock, Tags[?Key==`Tier`].Value | [0]]' \
  --output table

# 3. IGW
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId'

# 4. NAT Gateway
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[0].[NatGatewayId, State, NatGatewayAddresses[0].PublicIp]'

# 5. Routes (doit afficher 0.0.0.0/0 -> igw-xxx pour public, -> nat-xxx pour private)
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[].[Tags[?Key==`Name`].Value | [0], Routes[?DestinationCidrBlock==`0.0.0.0/0`].[GatewayId, NatGatewayId]]'

# 6. Security Group
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*bastion*"
```

## Nettoyage OBLIGATOIRE

```bash
terraform destroy -auto-approve
# Prend ~2-3 min (NAT Gateway lent a detruire)
```

Vérifier qu'il ne reste rien :

```bash
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
# Doit retourner [] si aucun NAT Gateway n'est actif
```

## Troubleshooting

| Erreur | Cause | Fix |
|---|---|---|
| `VpcLimitExceeded` | 5 VPC max par région | Détruire un ancien VPC |
| `NatGatewayLimitExceeded` | 5 NAT max par AZ | Détruire un ancien NAT |
| NAT Gateway en `pending` indéfiniment | `depends_on` manquant sur IGW | Le code contient le `depends_on`, vérifier qu'il n'a pas été supprimé |
| `InvalidGroup.Duplicate` au re-apply | SG déjà créé et pas supprimé | `terraform destroy` complet d'abord |
| `destroy` met 5 min | Normal : NAT + EIP séquentiels | Patienter |

## En production, à changer

- `single_nat_gateway` = false → 1 NAT par AZ (coût × 2, HA réseau)
- VPC Flow Logs activés (~5-10 €/mois)
- VPC endpoints S3 et DynamoDB (gratuits, évitent trafic NAT)
- `bastion_allowed_cidr` = votre IP publique/32, jamais 0.0.0.0/0
- Tags `kubernetes.io/role/elb = 1` sur subnets si EKS prévu
- Bastion remplacé par AWS Systems Manager Session Manager
