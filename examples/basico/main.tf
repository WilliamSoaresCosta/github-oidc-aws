# Exemplo: o deploy do site só pode vir da branch main do repositório "meu-site".
provider "aws" {
  region = "us-east-1"
}

module "github_oidc" {
  source = "github.com/WilliamSoaresCosta/github-oidc-aws?ref=v1.0.0"

  role_name     = "github-deploy-meu-site"
  github_org    = "minha-org"
  github_org_id = 12345678 # gh api orgs/minha-org --jq .id

  repositories = [
    {
      name = "meu-site"
      id   = 87654321 # gh api repos/minha-org/meu-site --jq .id
      refs = ["refs/heads/main"]
    },
  ]

  # Só o que o deploy precisa: escrever no bucket do site
  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::meu-site-bucket", "arn:aws:s3:::meu-site-bucket/*"]
    }]
  })

  tags = {
    ManagedBy = "terraform"
  }
}

output "role_arn" {
  value = module.github_oidc.role_arn
}
