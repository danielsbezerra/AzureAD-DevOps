# All resources and attributes names
# Use only in the name attributes of its own, not at other resources name references
locals {
  wafgw_name                     = "${var.env}-${var.organization}-${var.main_resource}"
  rg_name                        = "Antecipa_Producao_WAFGW" //"${local.wafgw_name}-rg"
  frontend_pip_name              = "${local.wafgw_name}-fepip"
  net_name                       = "${var.env}-${var.organization}-vnet"
  snet_name                      = "${local.wafgw_name}-snet"
  wafgw_ip_configuration_name    = "${local.wafgw_name}-wafgwcfgpip"
  frontend_ip_configuration_name = "${local.wafgw_name}-fecfgpip"
  frontend_port_name             = "${local.wafgw_name}-feport"
  backend_address_pool_name      = "${local.wafgw_name}-bepool"
  http_setting_name              = "${local.wafgw_name}-behtset"
  affinity_cookie_name           = "${local.wafgw_name}-beafck"
  listener_name                  = "${local.wafgw_name}-lstn"
  probe_name                     = "${local.wafgw_name}-prb"
  request_routing_rule_name      = "${local.wafgw_name}-rule"
  cert_name                      = "${var.organization}-cert"
  auth_cert_name                 = "${var.organization}-auth-cert"
}


resource "azurerm_resource_group" "rg" {
  name     = "${local.rg_name}"
  location = "${var.location}"
  tags = {
    env = "${var.env}"
    resource = "${var.main_resource}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.net_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  address_space       = ["${var.vnet_range}"]
  tags = {
    environment = "${var.env}"
    resource    = "${var.main_resource}"
  }
}

resource "azurerm_subnet" "snet" {
  name                 = "${local.snet_name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "${var.snet_range}"
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.frontend_pip_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags = {
    environment = "${var.env}"
    resource    = "${var.main_resource}"
  }
}


resource "azurerm_application_gateway" "wafgw" {
  name                = "${local.wafgw_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  enable_http2        = true
  tags = {
    environment = "${var.env}"
    resource    = "${var.main_resource}"
  }

  # v2 not all regions yet
  # name: [Standard_Small Standard_Medium Standard_Large Standard_v2 WAF_Large WAF_Medium WAF_v2]
  # tier: [Standard Standard_v2 WAF WAF_v2]
  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 2
  }

  ssl_certificate {
    name     = "${local.cert_name}"
    data     = "${filebase64("./certificate/antecipa.com.pfx")}"
    password = "${var.certificate_password}"
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.pip.id}"
  }

  frontend_port {
	  name = "${local.frontend_port_name}"
	  port = "${var.use_ssl ? 443 : 80}"
	}

  gateway_ip_configuration {
    name      = "${local.wafgw_ip_configuration_name}"
    subnet_id = "${azurerm_subnet.snet.id}"
  }

  probe {
    name                = "${local.probe_name}"
    protocol            = "${var.use_ssl ? "Https" : "Http"}"
    path                = "/"
    interval            = 5
    host                = "${var.backend_fqds}"
    timeout             = 4
    unhealthy_threshold = 3
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
    fqdns = ["${var.backend_fqds}"]
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "${var.use_ssl ? "Https" : "Http"}"
    ssl_certificate_name           = "${var.use_ssl ? "${local.cert_name}" : 0 }"
  }

  backend_http_settings {
      name                  = "${local.http_setting_name}"
      cookie_based_affinity = "Enabled"
      affinity_cookie_name  = "${local.affinity_cookie_name}"
      protocol              = "${var.use_ssl ? "Https" : "Http"}"
      port                  = "${var.use_ssl ? 443 : 80}"
      request_timeout       = 5
      probe_name            = "${local.probe_name}"
      authentication_certificate {
        name = "${local.auth_cert_name}"
      }
  }

  authentication_certificate {
    name = "${local.auth_cert_name}"
    data = "${base64encode(file("./certificate/antecipa.com.cer"))}"
  }

  waf_configuration {
    firewall_mode    = "Detection" // "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
    enabled          = true
  }

}
