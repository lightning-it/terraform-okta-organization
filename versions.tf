terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    okta = {
      source  = "okta/okta"
      version = ">= 6.13.0, < 7.0.0"
    }
  }
}
