output "ports" {
  description = "VM port of each copy of the app"
  value       = [for c in docker_container.app : c.ports[0].external]
}
