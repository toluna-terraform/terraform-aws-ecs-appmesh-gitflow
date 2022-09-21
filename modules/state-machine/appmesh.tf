# These appmesh gw-route, virtual service, virtual router, routes are created for testing
# viz., for integration tests and stress tests
# Similar resources for accessing ECS resources on regular course are already created part of ECS module

resource "aws_appmesh_virtual_router" "virtual_router" {
  name       = "vr-${var.app_name}-${var.env_name}-test"
  mesh_name  = "${var.appmesh_name}"
  mesh_owner = "${var.appmesh_owner}"

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }
}


resource "aws_appmesh_virtual_service" "virtual_service" {
  name       = "${var.env_name}.${var.namespace}-test"
  mesh_name  = "${var.appmesh_name}"
  mesh_owner = "${var.appmesh_owner}"

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.virtual_router.name
      }
    }
  }
}

resource "aws_appmesh_route" "route" {
  name                = "route-${var.app_name}-${var.env_name}"
  mesh_name           = "${var.appmesh_name}"
  mesh_owner          = "${var.appmesh_owner}"
  virtual_router_name = aws_appmesh_virtual_router.virtual_router.name
  spec {
    http_route {
      match {
        prefix = "/"
      }

      action {
        weighted_target {
          virtual_node = "vn-${var.app_name}-${var.env_name}-green"
          weight       = 100
        }
        weighted_target {
          virtual_node = "vn-${var.app_name}-${var.env_name}-blue"
          weight       = 0
        }
      }
    }
  }
}



resource "aws_appmesh_gateway_route" "gw-route" {
  # count = var.access_by_gateway_route == true ? 1: 0

  provider             = aws.app_mesh
  name                 = "gw-${var.appmesh_name}-${var.app_name}-${var.env_name}-route-test"
  mesh_name            = var.appmesh_name
  mesh_owner           = var.appmesh_owner
  virtual_gateway_name = "gw-${var.appmesh_name}"

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.virtual_service.name
          }
        }
      }

      match {
        prefix = var.env_name == var.appmesh_name ? "/${var.app_name}/test" : "/${var.env_name}/${var.app_name}/test"
      }
    }
  }
}

