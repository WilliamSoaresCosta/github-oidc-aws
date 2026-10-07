# terraform test: confere a trust policy sem criar nada na AWS (provider simulado).
mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  role_name  = "teste"
  github_org = "minha-org"
}

run "formato_classico_sem_ids" {
  command = plan

  variables {
    repositories = [{ name = "app", refs = ["refs/heads/main"] }]
  }

  assert {
    condition     = output.subjects == tolist(["repo:minha-org/app:ref:refs/heads/main"])
    error_message = "Sem IDs, o sub deveria usar dono/repo."
  }
}

run "formato_com_ids_imutaveis" {
  command = plan

  variables {
    github_org_id = 111
    repositories = [{
      name         = "app"
      id           = 222
      refs         = ["refs/heads/develop"]
      environments = ["producao"]
    }]
  }

  assert {
    condition = output.subjects == tolist([
      "repo:minha-org@111/app@222:ref:refs/heads/develop",
      "repo:minha-org@111/app@222:environment:producao",
    ])
    error_message = "Com IDs, o sub deveria usar dono@id/repo@id."
  }
}

run "recusa_curinga_no_repo" {
  command = plan

  variables {
    repositories = [{ name = "*", refs = ["refs/heads/main"] }]
  }

  expect_failures = [var.repositories]
}

run "recusa_repo_sem_ref" {
  command = plan

  variables {
    repositories = [{ name = "app" }]
  }

  expect_failures = [var.repositories]
}
