locals {
  labels = merge(var.labels, {
    app = "postgresql"
    deploymentName = var.name
  })

  selectors = merge(var.selectors, {
    app = "postgresql"
    deploymentName = var.name
  })
}

# create a namespace
resource "kubernetes_namespace" "pgsql-namespace" {
  metadata {
    name = var.namespace
  }
}

# create a config map
resource "kubernetes_config_map" "pgsql-config" {
  metadata {
    name = "pgsql-config"
    namespace= var.namespace
  }

  data = {
  #  POSTGRES_DB= var.databasename
  #  POSTGRES_USER= var.adminuser
    POSTGRES_PASSWORD=var.adminpassword
    PGDATA="/var/lib/postgresql/data/pgdata"
  }
}


# create a config map for populate volume init
resource "kubernetes_config_map" "pgsql-init" {
  metadata {
    name = "pgsql-init"
    namespace= var.namespace
  }

  data = {
  "init.sh" = "${templatefile("initdbsq.tftpl", { database_name = var.databasename, sonar_user = var.sonarusers, sonar_pass = var.sonarpass })}"
  }
 }


# create a PVC for database (Persistent volume Claim)

resource "kubernetes_persistent_volume_claim" "pgsql-pvc" {
  metadata {
    name = var.pvc
    namespace = var.namespace
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.pvc_pgsql_size
      }
    }
  }
}


# create a PostgreSQL Deployment

resource "kubernetes_deployment" "pgsql-deployment" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = local.labels
  }

  spec {
    replicas = 1 
    selector {
      match_labels = local.selectors
    }

    template {
      metadata {
        name = "pgsql"
        labels = local.labels
      }

      spec {
        volume {
          name = "initscript"
          config_map {
                 name="pgsql-init"
                 }    
         }          
        volume {
          name = "postgredb"
          persistent_volume_claim {
            claim_name = var.pvc 
          }
        }
	termination_grace_period_seconds=10

        container {
          name = "postgredb"
          image = "${var.pgsql_image_url}:${var.pgsql_image_tag}"

          port {
            container_port = 5432
          }

          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name = "postgredb"
          }
           volume_mount {
            mount_path = "/docker-entrypoint-initdb.d"
            name = "initscript"
          }

          env_from {
            config_map_ref {
               name ="pgsql-config"

             }
           }  

        }
      }
    }
  }
  depends_on = [
  kubernetes_config_map.pgsql-config
  ]
}

# Create a PostgreSQL service

resource "kubernetes_service" "pgsql-svc1" {
  metadata {
    name = "${var.name}-service"
    namespace = var.namespace
  }

  spec {
    port {
      port = 5432
      target_port = 5432
    }

    selector = local.selectors

    type = "LoadBalancer"
  }
}

# Patch Ingress map : add postgresql service

resource "null_resource" "patch_configmap_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch configmap ${var.ingress_mapconfig} --patch '{"data":{"5432":"default/${var.name}-service:5432"}}';
    EOT
  }
  depends_on = [
    kubernetes_service.pgsql-svc1
  ]
}

# Patch Ingress deployment : add postgresql service

resource "null_resource" "patch_deployment_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch deployment ${var.ingress_deployment} --patch "$(cat patch-ingress-nginx-deploy.yaml)";
    EOT
  }
  depends_on = [
    kubernetes_service.pgsql-svc1,null_resource.patch_configmap_ingress
  ]
}

# Create a local variable for the cluster ip.
locals {
  cluster_ip = kubernetes_service.pgsql-svc1.spec.0.cluster_ip

   depends_on = [
    kubernetes_service.pgsql-svc1,null_resource.patch_configmap_ingress,null_resource.patch_deployment_ingress
  ]
}

# Show SonarQube URL access
output "jdbc_url" {
  value = "SonarQube JDBC URL Access : User=${var.sonarusers} Password=${var.sonarpass} URL=jdbc:postgresql://${local.cluster_ip}:5432/${var.databasename}"
}

