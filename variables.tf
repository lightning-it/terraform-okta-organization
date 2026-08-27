variable "groups" {
  description = "Okta groups managed by this module, keyed by a caller-owned stable identifier."
  type = map(object({
    name        = string
    description = optional(string, "")
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, group in var.groups :
      trimspace(key) != "" && trimspace(group.name) != ""
    ])
    error_message = "Group keys and names must not be empty."
  }

  validation {
    condition = length(distinct([
      for group in values(var.groups) : lower(trimspace(group.name))
    ])) == length(var.groups)
    error_message = "Every managed Okta group must have a unique name."
  }
}

variable "group_memberships" {
  description = "Authoritative memberships for selected managed groups. Omit a group to leave its membership unmanaged."
  type = map(object({
    group_key       = string
    user_ids        = set(string)
    track_all_users = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for membership in values(var.group_memberships) :
      contains(keys(var.groups), membership.group_key)
    ])
    error_message = "Every group membership must reference a key declared in groups."
  }

  validation {
    condition = alltrue(flatten([
      for membership in values(var.group_memberships) : [
        for user_id in membership.user_ids : trimspace(user_id) != ""
      ]
    ]))
    error_message = "User IDs in group memberships must not be empty."
  }
}

variable "app_group_assignments" {
  description = "Authoritative group assignment sets for Okta applications, keyed by a caller-owned stable identifier."
  type = map(object({
    app_id     = string
    group_keys = set(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.app_group_assignments) :
      trimspace(assignment.app_id) != "" && alltrue([
        for group_key in assignment.group_keys : contains(keys(var.groups), group_key)
      ])
    ])
    error_message = "Application assignments require a non-empty app ID and group keys declared in groups."
  }
}

variable "group_push_mappings" {
  description = "SCIM Group Push mappings for managed groups, keyed by a caller-owned stable identifier."
  type = map(object({
    app_id            = string
    source_group_key  = string
    target_group_name = optional(string)
    status            = optional(string, "ACTIVE")
  }))
  default = {}

  validation {
    condition = alltrue([
      for mapping in values(var.group_push_mappings) :
      trimspace(mapping.app_id) != "" && contains(keys(var.groups), mapping.source_group_key)
    ])
    error_message = "Every Group Push mapping requires a non-empty app ID and a source group declared in groups."
  }

  validation {
    condition = alltrue([
      for mapping in values(var.group_push_mappings) :
      contains(["ACTIVE", "INACTIVE"], mapping.status)
    ])
    error_message = "Group Push status must be ACTIVE or INACTIVE."
  }
}
