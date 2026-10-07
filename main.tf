locals {
  oidc_host = "token.actions.githubusercontent.com"

  # Prefixo do "sub" de cada repositório.
  # Com IDs: dono@<id>/repo@<id> (imutável: repo apagado e recriado com o mesmo nome NÃO herda a permissão).
  # Sem IDs: dono/repo (formato clássico).
  repo_prefix = {
    for r in var.repositories : r.name => (
      var.github_org_id != null && r.id != null
      ? "${var.github_org}@${var.github_org_id}/${r.name}@${r.id}"
      : "${var.github_org}/${r.name}"
    )
  }

  subjects = distinct(flatten([
    for r in var.repositories : concat(
      [for ref in r.refs : "repo:${local.repo_prefix[r.name]}:ref:${ref}"],
      [for env in r.environments : "repo:${local.repo_prefix[r.name]}:environment:${env}"],
    )
  ]))

  oidc_provider_arn = (
    var.create_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )
}

# Provedor OIDC do GitHub (um por conta AWS)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://${local.oidc_host}"
}

# Quem pode assumir a role: só tokens do GitHub, para a AWS, vindos dos repos e refs listados
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals (e não StringLike): só entra exatamente quem está na lista
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = "Assumida pelo GitHub Actions via OIDC (sem access key)"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy_json == null ? 0 : 1

  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}
