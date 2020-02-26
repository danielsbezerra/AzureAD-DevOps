provider "azurerm" {
  version         = "=1.28.0"
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
}