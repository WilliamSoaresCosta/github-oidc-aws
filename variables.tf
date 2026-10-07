variable "role_name" {
  description = "Nome da role que o GitHub Actions vai assumir"
  type        = string
}

variable "github_org" {
  description = "Dono dos repositórios no GitHub (usuário ou organização)"
  type        = string
}

variable "github_org_id" {
  description = "ID numérico do dono (gh api users/<dono> --jq .id). Preenchido junto com o id do repo, usa o formato com IDs imutáveis"
  type        = number
  default     = null
}

variable "repositories" {
  description = <<-EOT
    Repositórios que podem assumir a role e de onde.
    - name: nome do repositório (sem curinga)
    - id: ID numérico (gh api repos/<dono>/<repo> --jq .id). Opcional
    - refs: branches/tags aceitas, ex.: ["refs/heads/main"]
    - environments: GitHub Environments aceitos, ex.: ["producao"]
  EOT
  type = list(object({
    name         = string
    id           = optional(number)
    refs         = optional(list(string), [])
    environments = optional(list(string), [])
  }))

  validation {
    condition     = length(var.repositories) > 0
    error_message = "Informe pelo menos um repositório."
  }

  validation {
    condition     = alltrue([for r in var.repositories : !strcontains(r.name, "*")])
    error_message = "Nome de repositório não aceita curinga: liberar a org inteira é exatamente o que este módulo evita."
  }

  validation {
    condition     = alltrue([for r in var.repositories : length(r.refs) + length(r.environments) > 0])
    error_message = "Cada repositório precisa de pelo menos uma ref ou um environment. Sem isso, qualquer branch assumiria a role."
  }

  validation {
    condition     = alltrue(flatten([for r in var.repositories : [for ref in r.refs : can(regex("^refs/(heads|tags)/", ref))]]))
    error_message = "Refs precisam começar com refs/heads/ ou refs/tags/ (ex.: refs/heads/main)."
  }
}

variable "create_oidc_provider" {
  description = "Cria o provedor OIDC do GitHub na conta. false = usa o que já existe (só pode existir um por conta)"
  type        = bool
  default     = true
}

variable "policy_arns" {
  description = "Policies gerenciadas anexadas à role. Dê só o que o pipeline precisa"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Policy inline opcional (JSON), para permissões bem específicas"
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Duração máxima da credencial, em segundos (padrão 1 hora)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 43200
    error_message = "Entre 900 (15 min) e 43200 (12 h)."
  }
}

variable "tags" {
  description = "Tags aplicadas nos recursos"
  type        = map(string)
  default     = {}
}
