locals {
  labels = merge(var.labels, {
    app = "mssql"
    deploymentName = var.name
  })

  selectors = merge(var.selectors, {
    app = "mssql"
    deploymentName = var.name
  })
}

# create a namespace
resource "kubernetes_namespace" "mssql-namespace" {
  metadata {
    name = var.namespace
  }
}

# create a secret for SQL Server user sa password 
resource "kubernetes_secret" "sqlsecret" {
  metadata {
    name = "sqlsecret"
    namespace= var.namespace
  }

  data = {
	sapassword= var.adminpassword 
  }
  type="Opaque"
}

# create storage class
resource "kubernetes_storage_class" "sonarclass" {
  metadata {
    name =  var.storage_class
    labels =  { 
       "addonmanager.kubernetes.io/mode" = "EnsureExists"
       "kubernetes.io/cluster-service" = "true"
       } 
  }

  storage_provisioner = "disk.csi.azure.com"
  reclaim_policy      = "Delete"
  volume_binding_mode ="Immediate"
  allow_volume_expansion ="true"
  parameters = {
    "skuname" = "StandardSSD_LRS"
    "location" = "westeurope"
    "fsType" = "ext4"
    "kind"= "Managed"
  
  }
  allowed_topologies {
    match_label_expressions  {
        key = "topology.disk.csi.azure.com/zone"
        values = ["westeurope-1"]
    }  

  }  
}

# create a PVC for database (Persistent volume Claim)

resource "kubernetes_persistent_volume_claim" "mssql-pvc" {
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
        storage = var.pvc_mssql_size
      }
    }
  }
}

# create a MS SQL server Deployment

resource "kubernetes_deployment" "mssql-deployment" {
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
        name = "mssql"
        labels = local.labels
      }

      spec {
               
        volume {
          name = "mssqldb"
          persistent_volume_claim {
            claim_name = var.pvc 
          }
        }
	      termination_grace_period_seconds=30

        security_context {
          fs_group=10001
         
	      }

        container {
          name = "mssql"
          image = "${var.mssql_image_url}:${var.mssql_image_tag}"

          port {
            container_port = 1433 
          }

          volume_mount {
            mount_path = "/var/opt/mssql"
            name = "mssqldb"
          }
         
          env {
            name = "MSSQL_PID"
            value = "Developer" 
          }

          env {
            name = "ACCEPT_EULA"
            value = "Y" 
          }

          env {
            name = "SA_PASSWORD"
            value_from {
		          secret_key_ref {
		            name= "sqlsecret"
		            key= "sapassword"
		        }

	       }
          }

        }
      }
    }
  }
}

# Create a MSSQL service

resource "kubernetes_service" "mssql-svc1" {
  metadata {
    name = "${var.name}-service"
    namespace = var.namespace
  }

  spec {
    port {
      port = 1433
      target_port = 1433
    }

    selector = local.selectors

    type = "LoadBalancer"
  }
}

# Patch Ingress map : add mssql service

resource "null_resource" "patch_configmap_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch configmap ${var.ingress_mapconfig} --patch '{"data":{"1433":"default/${var.name}-service:1433"}}';
    EOT
  }
  depends_on = [
    kubernetes_service.mssql-svc1
  ]
}

# Patch Ingress deployment : add mssql service

resource "null_resource" "patch_deployment_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch deployment ${var.ingress_deployment} --patch "$(cat patch-ingress-nginx-deploy.yaml)";
    EOT
  }
  depends_on = [
    kubernetes_service.mssql-svc1,null_resource.patch_configmap_ingress
  ]
}
# By running sqlcmd with a 60 second timeout 
resource "time_sleep" "wait_120_seconds" {
  depends_on = [kubernetes_deployment.mssql-deployment]

  create_duration = "60s"
}
# Create a local variable for the load balancer ip.
locals {
  lb_ip = kubernetes_service.mssql-svc1.status.0.load_balancer.0.ingress.0.ip
  lo_ip = kubernetes_service.mssql-svc1.spec.0.cluster_ip
   depends_on = [
    kubernetes_service.mssql-svc1,null_resource.patch_configmap_ingress,null_resource.patch_deployment_ingress
  ]
}

# Create sonarqube DataBase : sonarqube9 and sonarqube user
# Setup a password sonarqube user in setsonarqube.sql
#
resource "null_resource" "init_mssql" {
  provisioner "local-exec" {
    command = "sqlcmd -U sa -P ${var.adminpassword} -S ${local.lb_ip} -i setsonarqube.sql"
   
  }
  depends_on = [
    kubernetes_service.mssql-svc1,null_resource.patch_configmap_ingress,null_resource.patch_deployment_ingress,kubernetes_deployment.mssql-deployment,time_sleep.wait_120_seconds
  ]
}

# Show public ip address for access sql server database
output "load_balancer_ip" {
  value = local.lb_ip
}
# Show jdbc user for SonarQube Access for set in SonarQube Deployment
output "sonar_jdbc_user" {
  value = "sonarqube"
}
# Show jdbc password for SonarQube Access for set in SonarQube Deployment
output "sonar_jdbc_password" {
  value = "sonarqube20@"
}
# Show jdbc url for SonarQube Access for set in SonarQube Deployment
output "sonar_jdbc_url" {
  value = "jdbc:sqlserver://${local.lo_ip}:1433;databaseName=sonarqube9;encrypt=true;trustServerCertificate=true;integratedSecurity=false"
}

# Show local ip address for sql server service
output "load_local_ip" {
  value = local.lo_ip
}



