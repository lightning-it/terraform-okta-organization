resource "okta_group" "this" {
  for_each = var.groups

  name        = each.value.name
  description = each.value.description

  lifecycle {
    prevent_destroy = true
  }
}

resource "okta_group_memberships" "this" {
  for_each = var.group_memberships

  group_id        = okta_group.this[each.value.group_key].id
  users           = sort(tolist(each.value.user_ids))
  track_all_users = each.value.track_all_users

  lifecycle {
    prevent_destroy = true
  }
}

resource "okta_app_group_assignments" "this" {
  for_each = var.app_group_assignments

  app_id = each.value.app_id

  dynamic "group" {
    for_each = each.value.group_keys

    content {
      id = okta_group.this[group.value].id
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "okta_push_group" "this" {
  for_each = var.group_push_mappings

  app_id                         = each.value.app_id
  source_group_id                = okta_group.this[each.value.source_group_key].id
  target_group_name              = each.value.target_group_name
  status                         = each.value.status
  delete_target_group_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}
