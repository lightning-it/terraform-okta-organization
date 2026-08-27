# Migrating to `organization/okta`

The public module source moved from `lightning-it/instance/okta` to
`lightning-it/organization/okta` in version `1.1.0`. The module resource
addresses did not change, so updating only `source` and `version` does not move
or recreate resources already recorded under the calling module address.

Run `terraform init -upgrade` after changing the source, then review a saved
plan. Stop if Terraform proposes a create, delete, or replacement.

## Adopting existing Okta objects

Imports belong in the private root configuration because import identifiers are
tenant-specific. Import each live object directly into its module address
before the first apply.

```hcl
import {
  to = module.identity_groups.okta_group.this["operators"]
  id = var.operators_group_id
}

import {
  to = module.identity_groups.okta_group_memberships.this["operators"]
  id = "${var.operators_group_id}/true"
}

import {
  to = module.identity_groups.okta_app_group_assignments.this["provisioning"]
  id = var.provisioning_app_id
}

import {
  to = module.identity_groups.okta_push_group.this["operators"]
  id = "${var.provisioning_app_id}/${var.operators_push_mapping_id}"
}
```

The first saved plan must contain only the expected imports and reviewed
in-place updates. Stop if Terraform proposes deleting or replacing a user,
group, application, or Group Push mapping.
