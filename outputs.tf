output "group_ids" {
  description = "Okta group IDs keyed by the stable caller-owned group key."
  value       = { for key, group in okta_group.this : key => group.id }
}

output "group_names" {
  description = "Okta group names keyed by the stable caller-owned group key."
  value       = { for key, group in okta_group.this : key => group.name }
}

output "group_push_mapping_ids" {
  description = "Okta Group Push mapping IDs keyed by the stable caller-owned mapping key."
  value       = { for key, mapping in okta_push_group.this : key => mapping.id }
}
