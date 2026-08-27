mock_provider "okta" {}

run "empty_configuration" {
  command = plan

  assert {
    condition     = length(output.group_ids) == 0
    error_message = "The default configuration must not manage any Okta groups."
  }
}

run "complete_configuration" {
  command = plan

  variables {
    groups = {
      operators = {
        name        = "example-operators"
        description = "Operators of the example service."
      }
      users = {
        name        = "example-users"
        description = "Users of the example service."
      }
    }

    group_memberships = {
      operators = {
        group_key = "operators"
        user_ids  = ["example-user-id"]
      }
    }

    app_group_assignments = {
      provisioning = {
        app_id     = "example-app-id"
        group_keys = ["operators", "users"]
      }
    }

    group_push_mappings = {
      operators = {
        app_id           = "example-app-id"
        source_group_key = "operators"
      }
    }
  }

  assert {
    condition     = okta_group.this["operators"].name == "example-operators"
    error_message = "The module must preserve the configured group name."
  }

  assert {
    condition     = toset(okta_group_memberships.this["operators"].users) == toset(["example-user-id"])
    error_message = "The module must render the authoritative membership set."
  }

  assert {
    condition     = okta_push_group.this["operators"].delete_target_group_on_destroy == false
    error_message = "Group Push mappings must never delete the target group on destroy."
  }
}
