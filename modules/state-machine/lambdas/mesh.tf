resource "aws_appmesh_route" "service_route" {
  name                = "route-${var.app_name}-${var.env_name}-test"
  mesh_name           = "${var.app_mesh_name}"
  mesh_owner          = "${var.app_mesh_account_id}"
  virtual_router_name = "vr-${var.app_mesh_name}-${var.env_name}"
  spec {
    http_route {
      match {
        prefix = "/"
      }

      action {
        weighted_target {
          virtual_node = "vn-${local.prefix}-green"
          weight       = 0
        }
        weighted_target {
          virtual_node = "vn-${local.prefix}-blue"
          weight       = 100
        }
      }
    }
  }

  # Ignoring changes made by code_deploy controller
  lifecycle {
    ignore_changes = [
      spec[0].http_route[0].action
    ]
  }
}
