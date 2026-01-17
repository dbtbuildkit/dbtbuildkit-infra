# Módulo Terraform - DBT BuildKit para AWS

Este módulo Terraform cria uma infraestrutura completa na AWS para executar projetos DBT usando AWS CodeBuild. O módulo é totalmente configurável e pode ser reutilizado por diferentes equipes e empresas.

## Características

- ✅ Criação automática de projetos CodeBuild baseados em arquivo YAML de configuração
- ✅ Suporte a múltiplos ambientes (dev, stg, prd)
- ✅ Agendamento de execuções via CloudWatch Events
- ✅ Integração nativa com GitHub ou SSH
- ✅ Suporte a múltiplos engines (Redshift, BigQuery, Snowflake, etc.)
- ✅ Notificações via Slack, Teams, Discord e SNS
- ✅ Gerenciamento de incidentes via AWS Systems Manager
- ✅ Permissões IAM configuráveis
- ✅ Suporte a VPC para execução em rede privada

## Pré-requisitos

1. **Conta AWS** com permissões adequadas
2. **Imagem Docker DBT** no ECR (ou fornecer URI completa)
3. **Conexão GitHub** (se usar integração nativa) - opcional
4. **Arquivo de configuração YAML** com os projetos DBT

## Estrutura de Arquivos

```
modules/dbt/
├── main.tf              # Recursos principais
├── variables.tf         # Variáveis do módulo
├── outputs.tf           # Outputs do módulo
├── buildspec.tpl        # Template do buildspec
└── README.md           # Esta documentação
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Arquivo de Configuração YAML

O módulo lê um arquivo YAML que define os projetos DBT a serem criados. O arquivo deve estar no diretório raiz do módulo ou em um caminho relativo especificado.

### Estrutura Básica

```yaml
codebuild:
  - name: projeto-exemplo
    active: true
    org: minha-org
    repo: meu-repo-dbt
    engine: redshift
    commands:
      - dbt run
      - dbt test
```

### Campos Obrigatórios

- `name`: Nome único do projeto
- `active`: `true` para criar o projeto, `false` para ignorar
- `org`: Organização do GitHub
- `repo`: Nome do repositório
- `engine`: Engine do DBT (redshift, bigquery, snowflake, etc.)
- `commands`: Lista de comandos DBT a executar

### Campos Opcionais

```yaml
codebuild:
  - name: projeto-completo
    active: true
    org: minha-org
    repo: meu-repo-dbt
    engine: redshift
    commands:
      - dbt run
      - dbt test
    # Configurações opcionais
    timeout: 120                    # Timeout em minutos (default: 60)
    compute_type: BUILD_GENERAL1_MEDIUM  # Tipo de instância (default: BUILD_GENERAL1_SMALL)
    schedule: "cron(0 2 * * ? *)"   # Agendamento CloudWatch Events
    
    # Configuração de Imagem Docker (ECR) - Por Projeto
    # Permite especificar um repositório ECR diferente para cada projeto
    ecr_repository: "dev-dbtbuildkit"  # Nome do repositório ECR (sem prefixo de conta/região)
    ecr_image_tag: "latest"           # Tag da imagem (opcional, padrão: usa variável do módulo)
    # Se ecr_repository não for especificado, usa o padrão: {env}-{ecr_dbt}
    # A URI completa será construída como: {account-id}.dkr.ecr.{region}.amazonaws.com/{ecr_repository}:{ecr_image_tag}
    
    # Notificações Slack
    slack-notification:
      active: true
      channel: "#data-alerts"
      secret_name: "slack-token"  # Nome do secret no AWS Secrets Manager (padrão: vazio)
    
    # Notificações Microsoft Teams
    teams-notification:
      active: true
      secret_name: "teams-webhook"  # Nome do secret no AWS Secrets Manager (padrão: vazio)
      # webhook_url: "https://outlook.office.com/webhook/..."  # Alternativa: URL direta (opcional)
    
    # Notificações Discord
    discord-notification:
      active: true
      secret_name: "discord-webhook"  # Nome do secret no AWS Secrets Manager (padrão: vazio)
      # webhook_url: "https://discord.com/api/webhooks/..."  # Alternativa: URL direta (opcional)
    
    # Notificações SNS
    sns-notification:
      active: true
      topic_arn: "arn:aws:sns:us-east-1:123456789012:dbt-notifications"  # ARN do tópico SNS
    
    # Elementary
    elementary:
      active: true
      channel: "#elementary-data"
      description: "Projeto de transformação de dados"
      gitpages: true
    
    # Gerenciamento de Incidentes
    incident-manager:
      active: true
      impact: 1
      incident-response-plan: "meu-plano-resposta"
    
    # Variáveis de ambiente customizadas
    environment_variables:
      CUSTOM_VAR: "valor"
    
    # Secrets do AWS Secrets Manager
    secrets_manager_variables:
      - DB_PASSWORD: "arn:aws:secretsmanager:us-east-1:123456789:secret:db-password"
    
    # Configuração VPC (opcional)
    vpc_config:
      vpc_id: "vpc-123456"
      subnets:
        - "subnet-123456"
        - "subnet-789012"
      security_group_ids:
        - "sg-123456"
    
    # Tabelas críticas para monitoramento
    critical_tables:
      - "schema.tabela_importante"
    
    # Tabelas não críticas
    not_critical_tables:
      - "schema.tabela_teste"
    
    # Notificações automáticas
    auto-notifications:
      - "evento1"
      - "evento2"
    
    # UTC offset
    utc: -3
```

## Integração com Módulo dbtbuildkit

Este módulo é tipicamente usado em conjunto com o módulo `dbtbuildkit`, que cria o repositório ECR e a conexão GitHub. Veja como integrar:

```hcl
# 1. Primeiro, crie a infraestrutura base (ECR + GitHub Connection)
module "dbtbuildkit" {
  source = "./modules/dbtbuildkit"
  
  project    = "meu-projeto"
  env        = "dev"
  aws_region = "us-east-1"
  
  tags = {
    Environment = "dev"
    Project     = "data-engineering"
  }
}

# 2. Depois, use os outputs no módulo dbt
module "dbt" {
  source = "./modules/dbt"
  
  project = "meu-projeto"
  env     = "dev"
  aws_region = "us-east-1"
  
  # Use a imagem ECR criada pelo módulo dbtbuildkit
  ecr_image_uri = "${module.dbtbuildkit.ecr_repository_url}:latest"
  
  # Use a conexão GitHub criada pelo módulo dbtbuildkit
  github_connection_arn = module.dbtbuildkit.github_connection_arn
  use_github_native     = true
  
  tags = {
    Environment = "dev"
    Project     = "data-engineering"
  }
}
```

**Nota Importante**: Certifique-se de que o módulo `dbtbuildkit` seja aplicado antes do módulo `dbt`, ou use `depends_on` explícito se necessário.

## Exemplos de Uso

### Exemplo 1: Uso Básico

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  project = "meu-projeto"
  env     = "dev"
  aws_region = "us-east-1"
  
  tags = {
    Environment = "dev"
    Project     = "data-engineering"
    Team        = "data-team"
  }
}
```

### Exemplo 2: Com Configurações Customizadas

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  project = "meu-projeto"
  env     = "prd"
  aws_region = "sa-east-1"
  
  # Imagem ECR customizada
  ecr_image_uri = "123456789012.dkr.ecr.sa-east-1.amazonaws.com/dbt-custom:v2.0"
  
  # GitHub nativo
  use_github_native   = true
  github_connection_arn = "arn:aws:codeconnections:sa-east-1:123456789012:connection/abc123"
  github_branch       = "main"
  
  # IAM customizado (sem permissões padrão)
  enable_default_iam_permissions = false
  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::meu-bucket/*"
    },
    {
      Effect   = "Allow"
      Action   = ["redshift-data:ExecuteStatement"]
      Resource = "*"
    }
  ]
  
  tags = {
    Environment = "prd"
    Project     = "data-engineering"
    Team        = "data-team"
    CostCenter  = "engineering"
  }
}
```

### Exemplo 3: Usando SSH ao invés de GitHub Nativo

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  project = "meu-projeto"
  env     = "dev"
  aws_region = "us-east-1"
  
  use_github_native = false
  
  # Secret ARN contendo a chave SSH
  # O secret deve estar configurado no arquivo YAML do projeto
  secrets_manager_variables = [
    {
      GITHUB_SSH_SECRET_ARN = "arn:aws:secretsmanager:us-east-1:123456789012:secret:github-ssh-key"
    }
  ]
  
  tags = {
    Environment = "dev"
    Project     = "data-engineering"
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Permissões IAM

O módulo suporta dois modos de permissões IAM:

### Modo Amplo (Padrão - Compatibilidade)

Quando `enable_default_iam_permissions = true` e `use_minimal_iam_policy = false` (padrão), o módulo cria uma política ampla com wildcards:

- `sts:*` - Assume roles e obter credenciais
- `logs:*` - CloudWatch Logs
- `s3:*` - Amazon S3
- `athena:*` - Amazon Athena
- `redshift:*` e `redshift-data:*` - Amazon Redshift
- `glue:*` - AWS Glue
- `secretsmanager:*` - AWS Secrets Manager
- `ecr:*` - Amazon ECR
- `ssm-incidents:*` e `ssm-contacts:*` - AWS Systems Manager
- `ec2:*` - Amazon EC2 (para VPC)
- `codeconnections:*` - AWS CodeConnections
- `dynamodb:*` - Amazon DynamoDB

**⚠️ Aviso**: Este modo viola o princípio de menor privilégio. Use apenas para desenvolvimento ou quando necessário.

### Modo Mínimo (Recomendado para Produção)

Quando `enable_default_iam_permissions = true` e `use_minimal_iam_policy = true`, o módulo cria uma política restritiva baseada no princípio de menor privilégio:

#### Permissões Base (Sempre Incluídas)

- **STS**: `GetCallerIdentity` - Identificar a conta AWS
- **CloudWatch Logs**: `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` - Apenas para logs do CodeBuild
- **S3**: `GetObject`, `PutObject` (e `ListBucket` se buckets específicos configurados)
- **Secrets Manager**: `GetSecretValue` - Apenas para secrets configurados
- **ECR**: `GetAuthorizationToken`, `BatchGetImage`, `GetDownloadUrlForLayer` - Apenas para pull de imagens
- **SSM Incidents**: `ListResponsePlans`, `StartIncident`, `CreateTimelineEvent`, `GetIncidentRecord`
- **SSM Contacts**: `GetContact`, `ListContacts`
- **CodeConnections**: `UseConnection` - Apenas se usar GitHub nativo

#### Permissões por Engine (Adicionadas Automaticamente)

As permissões específicas do engine são adicionadas automaticamente baseadas no `engine` configurado em cada projeto:

- **Redshift**: `redshift-data:ExecuteStatement`, `redshift-data:DescribeStatement`, `redshift-data:GetStatementResult`, `redshift:DescribeClusters`
- **Athena**: `athena:StartQueryExecution`, `athena:StopQueryExecution`, `athena:GetQueryExecution`, `athena:GetQueryResults`, `athena:GetWorkGroup`, `glue:GetDatabase`, `glue:GetTable`, `glue:GetPartitions`, `glue:CreateTable`, `glue:UpdateTable`
- **Glue**: `glue:GetDatabase`, `glue:GetTable`, `glue:GetPartitions`, `glue:CreateTable`, `glue:UpdateTable`, `glue:DeleteTable`, `glue:GetJob`, `glue:StartJobRun`
- **Snowflake/BigQuery/Postgres/Databricks**: Não requerem permissões AWS específicas

#### Permissões VPC (Adicionadas Automaticamente)

Se um projeto usar `vpc_config`, as seguintes permissões EC2 são adicionadas:
- `ec2:DescribeNetworkInterfaces`, `ec2:CreateNetworkInterface`, `ec2:DeleteNetworkInterface`
- `ec2:DescribeSecurityGroups`, `ec2:DescribeSubnets`, `ec2:DescribeVpcs`

### Exemplo: Usando Política Mínima

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  project = "meu-projeto"
  env     = "prd"
  aws_region = "sa-east-1"
  
  # Ativar política mínima
  enable_default_iam_permissions = true
  use_minimal_iam_policy         = true
  
  # Configurar recursos específicos permitidos
  s3_buckets = [
    "meu-bucket-dbt-data",
    "meu-bucket-dbt-artifacts"
  ]
  
  secrets_manager_secrets = [
    "arn:aws:secretsmanager:sa-east-1:123456789012:secret:slack-token-*",
    "arn:aws:secretsmanager:sa-east-1:123456789012:secret:teams-webhook-*"
  ]
  
  ecr_repository_arns = [
    "arn:aws:ecr:sa-east-1:123456789012:repository/prd-dbtbuildkit"
  ]
  
  # Anexar políticas IAM adicionais (opcional)
  # Útil para adicionar permissões específicas da organização
  additional_iam_policy_arns = [
    "arn:aws:iam::123456789012:policy/MinhaPolicyCustomizada",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"  # Exemplo de política AWS gerenciada
  ]
  
  tags = {
    Environment = "prd"
    Project     = "data-engineering"
  }
}
```

**Nota**: Se as listas de recursos específicos estiverem vazias, o módulo permite acesso a todos os recursos do tipo na conta (ainda com permissões restritivas). Para máxima segurança, sempre especifique recursos específicos.

### Modo Customizado

Para controle total, use `enable_default_iam_permissions = false` e defina permissões específicas via `iam_policy_statements`:

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  enable_default_iam_permissions = false
  iam_policy_statements = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject"]
      Resource = "arn:aws:s3:::meu-bucket/*"
    },
    {
      Effect   = "Allow"
      Action   = ["redshift-data:ExecuteStatement"]
      Resource = "*"
    }
  ]
  
  # Você também pode combinar com políticas gerenciadas adicionais
  additional_iam_policy_arns = [
    "arn:aws:iam::123456789012:policy/MinhaPolicyCustomizada"
  ]
}
```

### Combinando Política Mínima com Políticas Adicionais

Você pode combinar a política mínima com políticas gerenciadas adicionais para flexibilidade máxima:

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  # Usar política mínima como base
  enable_default_iam_permissions = true
  use_minimal_iam_policy         = true
  
  # Adicionar políticas gerenciadas para permissões específicas
  additional_iam_policy_arns = [
    "arn:aws:iam::123456789012:policy/AcessoKMS",
    "arn:aws:iam::123456789012:policy/AcessoDynamoDB"
  ]
  
  # Você também pode combinar com políticas gerenciadas adicionais
  additional_iam_policy_arns = [
    "arn:aws:iam::123456789012:policy/MinhaPolicyCustomizada"
  ]
}
```

### Combinando Política Mínima com Políticas Adicionais

Você pode combinar a política mínima com políticas gerenciadas adicionais para flexibilidade máxima:

```hcl
module "dbt" {
  source = "./modules/dbt"
  
  # Usar política mínima como base
  enable_default_iam_permissions = true
  use_minimal_iam_policy         = true
  
  # Adicionar políticas gerenciadas para permissões específicas
  additional_iam_policy_arns = [
    "arn:aws:iam::123456789012:policy/AcessoKMS",
    "arn:aws:iam::123456789012:policy/AcessoDynamoDB"
  ]
}
```

## Agendamento de Execuções

Use expressões cron ou rate do CloudWatch Events:

```yaml
schedule: "cron(0 2 * * ? *)"    # Diariamente às 2h UTC
schedule: "rate(6 hours)"        # A cada 6 horas
schedule: "cron(0 9 ? * MON-FRI)" # Dias úteis às 9h UTC
```

## Suporte a Múltiplos Ambientes

O módulo cria todos os projetos definidos no arquivo YAML, independente do ambiente. O controle de quais projetos criar em cada ambiente deve ser feito pelo usuário através da configuração YAML (usando `active: true/false` ou diferentes arquivos de configuração por ambiente).

## Troubleshooting

### Erro: "github_connection_arn é obrigatório"

**Solução**: Configure `github_connection_arn` quando `use_github_native = true`, ou defina `use_github_native = false` para usar SSH.

### Erro: "Imagem ECR não encontrada"

**Solução**: 
- Verifique se a imagem existe no ECR
- Se estiver usando `ecr_repository` no YAML, verifique se o nome do repositório está correto
- Como alternativa, forneça `ecr_image_uri` completo no módulo ou no projeto YAML
- Certifique-se de que a tag da imagem especificada existe no repositório

### Projetos não são criados

**Solução**: 
1. Verifique se `active: true` no arquivo YAML
2. Verifique se todos os campos obrigatórios estão presentes
3. Verifique se o arquivo YAML está no caminho correto (definido em `file_name`)

## Contribuindo

Este módulo foi projetado para ser genérico e reutilizável. Ao contribuir:

1. Mantenha a compatibilidade com versões anteriores
2. Adicione documentação para novas variáveis
3. Inclua exemplos de uso
4. Teste em múltiplos ambientes

## Licença

Este módulo é fornecido como está. Use por sua conta e risco.
