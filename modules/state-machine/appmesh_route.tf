resource "aws_appmesh_route" "serviceb" {
  name                = "route-${local.app_name}-${local.env_name}-test"
  mesh_owner          = var.appmesh_owner
  mesh_name           = var.appmesh_name
  virtual_router_name = "vr-${local.app_name}-${local.env_name}"

  spec {
    http_route {
      match {
        prefix = "/"
      }

      action {
        weighted_target {
          virtual_node = "vn-${local.app_name}-${local.env_name}-${local.next_color}"
          weight       = 100
        }

      }
    }
  }
}