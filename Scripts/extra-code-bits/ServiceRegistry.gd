class_name ServiceRegistry
extends Resource

@export var services: Array[ServiceDefinition] = []


func get_service(service_id: StringName) -> ServiceDefinition:
	for service: ServiceDefinition in services:
		if service == null:
			continue

		if service.service_id == service_id:
			return service

	return null
