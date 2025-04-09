provider "azurerm" {
  subscription_id = "add subscription id"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "az-rg-hello-world-poc"
  location = "West Europe"
}

resource "azurerm_app_service_plan" "webapp-plan" {
  name                = "webappsecuritypoc-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = "hello-world-webapp-security-poc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.webapp-plan.id
  https_only = true
  site_config {
    min_tls_version = "1.2"
    ip_restriction {
        name = "Allow443"
        priority = 100
        action = "Allow"
        ip_address = "0.0.0.0/0"
        headers {
        x_azure_fdid      = []
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
    }

  }
  identity {
  type = "SystemAssigned"
  }
  app_settings = {
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}


# resource "azurerm_app_service_custom_hostname_binding" "customhostmane" {
#   hostname            = "helloworld.azurewebsites.net"
#   app_service_name    = azurerm_app_service.webapp.name
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_app_service_managed_certificate" "managed-certificate" {
#   custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.customhostmane.id
# }

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "hello-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_app_service_plan.webapp-plan.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        time_aggregation  = "Average"
        time_window       = "PT5M"
        metric_resource_id = azurerm_app_service_plan.webapp-plan.id
        operator           = "GreaterThan"
        threshold          = 70
        time_grain         = "PT1M"
        statistic          = "Average"
      }
      scale_action {
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "log-analytics" {
  name                = "log-analytics-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


resource "azurerm_monitor_diagnostic_setting" "diagnostic-setting" {
  name                       = "hello-world-diagnostics"
  target_resource_id         = azurerm_app_service.webapp.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-analytics.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_app_service_certificate" "self_signed" {
  name                = "self-signed-cert"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  pfx_blob            = filebase64("mycert.pfx")
  password            = "passwd"
}

resource "azurerm_app_service_custom_hostname_binding" "customhostmane" {
  hostname            = "hello-world-assessment.com"
  app_service_name    = azurerm_app_service.webapp.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_app_service_certificate_binding" "cert_binding" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.customhostmane.id
  certificate_id      = azurerm_app_service_certificate.self_signed.id
  ssl_state           = "SniEnabled"
}
