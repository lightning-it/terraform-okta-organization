# terraform-okta-organization

<!-- BEGIN LIT_QUALITY_BADGES -->

[![CI](https://github.com/lightning-it/terraform-okta-organization/actions/workflows/repository-quality.yml/badge.svg?branch=develop)](https://github.com/lightning-it/terraform-okta-organization/actions/workflows/repository-quality.yml)
[![Latest Release](https://img.shields.io/github/v/release/lightning-it/terraform-okta-organization?sort=semver)](https://github.com/lightning-it/terraform-okta-organization/releases/latest)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/lightning-it/terraform-okta-organization/badge)](https://scorecard.dev/viewer/?uri=github.com/lightning-it/terraform-okta-organization)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

<!-- END LIT_QUALITY_BADGES -->

<!-- BEGIN LIT_SHARED_RELEASE_MODEL -->

## Release and Quality Model

This repository follows the Lightning IT shared release and quality model.

See [RELEASE.md](./RELEASE.md) for:

- branch and release flow
- required quality checks
- test matrix
- release evidence
- artifact publishing
- supported repository-specific release behavior

Repository classification: **Terraform Module**.
Required test profiles: `pre-commit, terraform-fmt, terraform-validate, docs`.
Publishing targets: `terraform-registry`.

## Supported and Tested Platforms

| Platform / Product |                  Status | Validation         |
| ------------------ | ----------------------: | ------------------ |
| ubuntu-latest      |               Supported | Terraform validate |
| terraform          | Tested where applicable | Terraform validate |
| okta-provider      | Tested where applicable | Terraform validate |

<!-- END LIT_SHARED_RELEASE_MODEL -->

Reusable Terraform module for managing Okta groups, selected authoritative
memberships, application group-assignment sets, and SCIM Group Push mappings.

The module is deliberately tenant-neutral. It contains no backend, provider
credentials, organization names, user identities, application IDs, import IDs,
or environment-specific workflows. A private root configuration owns those
values and the Terraform state.

## Usage

```hcl
provider "okta" {
  org_name    = var.okta_org_name
  base_url    = var.okta_base_url
  client_id   = var.okta_client_id
  private_key = var.okta_private_key
  scopes      = ["okta.apps.manage", "okta.groups.manage"]
}

module "identity_groups" {
  source  = "lightning-it/organization/okta"
  version = "1.1.0"

  groups = {
    operators = {
      name        = "example-operators"
      description = "Operators of the example service."
    }
  }

  group_memberships = {
    operators = {
      group_key = "operators"
      user_ids  = var.operator_user_ids
    }
  }

  app_group_assignments = {
    provisioning = {
      app_id     = var.provisioning_app_id
      group_keys = ["operators"]
    }
  }

  group_push_mappings = {
    operators = {
      app_id           = var.provisioning_app_id
      source_group_key = "operators"
    }
  }
}
```

Pin consumers to an immutable release tag. Do not consume a moving branch in a
production root module.

## Ownership boundaries

The calling root module is responsible for:

- configuring the Okta provider and its least-privilege credentials;
- selecting and protecting a remote-state backend;
- supplying all tenant-specific group names, user IDs, and application IDs;
- declaring imports for existing live resources;
- reviewing and approving every plan.

Omitting a group from `group_memberships` leaves its memberships unmanaged.
When a membership entry is present, its user set is authoritative. Application
assignment sets are authoritative for the referenced application.

Managed groups, memberships, application assignment sets, and Group Push
mappings use `prevent_destroy`. Group Push also sets
`delete_target_group_on_destroy = false`.

## Requirements

- Terraform `>= 1.9, < 2.0`
- Okta provider `>= 6.13, < 7.0`
