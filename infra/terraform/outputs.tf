output "resource_group_name" {
  description = "Name of the resource group hosting Koe-Kagami."
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = azurerm_container_registry.main.login_server
}

output "openai_endpoint" {
  description = "Endpoint of the Azure OpenAI account."
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_deployment_name" {
  description = "Name of the Azure OpenAI model deployment."
  value       = azurerm_cognitive_deployment.chat.name
}

output "ai_foundry_hub_id" {
  description = "Resource id of the Azure AI Foundry hub."
  value       = azurerm_ai_foundry.main.id
}

output "ai_foundry_project_id" {
  description = "Resource id of the Azure AI Foundry project."
  value       = azurerm_ai_foundry_project.main.id
}

output "backend_url" {
  description = "Public URL of the backend container app."
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "Public URL of the frontend container app."
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}
