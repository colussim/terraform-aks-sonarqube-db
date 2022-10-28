locals {
  labels = merge(var.labels, {
    app = "ora"
    deploymentName = var.name
  })

  selectors = merge(var.selectors, {
    app = "ora"
    deploymentName = var.name
  })
}

# create a namespace
resource "kubernetes_namespace" "ora-namespace" {
  metadata {
    name = var.namespace
  }
}

# create a config map
resource "kubernetes_config_map" "oracle-config" {
  metadata {
    name = "oracle-rdbms-config"
    namespace= var.namespace
  }

  data = {

  ORACLE_CHARACTERSET=var.charset
  ORACLE_EDITION=var.edition
  ORACLE_PDB=var.pdb
  TARGET_PDB=var.sonarqubedb
  }
  depends_on = [
  kubernetes_namespace.ora-namespace
  ]
}

# create a secret for oracle user sa password 
resource "kubernetes_secret" "orasecret" {
  metadata {
    name = "orasecret"
    namespace= var.namespace
  }

  data = {
	orapassword= var.adminpassword 
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

resource "kubernetes_persistent_volume_claim" "ora-pvc" {
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
        storage = var.pvc_ora_size
      }
    }
  }
}

# create a PVC for setup (Persistent volume Claim)


resource "kubernetes_persistent_volume_claim" "ora-setup-pvc" {
  metadata {
    name = var.pvc-setup
    namespace = var.namespace
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.pvc_ora_setup_size
      }
    }
  }
}

#
# create a config map for populate volume setup
resource "kubernetes_config_map" "ora-setup" {
  metadata {
    name = "ora-init"
    namespace= var.namespace
  }

  data = {
  "init.sh"="${file("initpdb.sh")}"
  }
}


# create a ORACLE server Deployment



resource "kubernetes_deployment" "ora-deployment" {
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
     strategy {
      type = "Recreate"
     }

    template {
      metadata {
        name = "ora"
        labels = local.labels
      }

      spec {
 
        volume {
          name =  "orasetup"
          config_map {
                 name="ora-init"
                 }      
                
         }   
          volume {
          name = "oradb"
          persistent_volume_claim {
            claim_name = var.pvc 
          }
        }
      
  
	      termination_grace_period_seconds=30

        security_context {
          fs_group=54321
          run_as_user = 54321
         
	      }

        container {
          name = "oraclexe"
          image = "${var.ora_image_url}:${var.ora_image_tag}"
         
          env_from {
            config_map_ref {
               name = "oracle-rdbms-config"
             }
           }  

          port {
            container_port = 1521
            name = "oracle-listener"

          }

          port {
            container_port = 5500
            name = "oem-express"

          }

          volume_mount {
            mount_path = "/opt/oracle/oradata"
            name = "oradb"
          }
          volume_mount {
            mount_path = "/container-entrypoint-initdb.d"
            name = "orasetup"
          }
         
          env {
            name = "ora_PID"
            value = "Developer" 
          }

          env {
            name = "ORACLE_PASSWORD"
            value_from {
		          secret_key_ref {
		            name= "orasecret"
		            key= "orapassword"
		        }

	       }
          }

        }
      

      }
    }
  }
}

# Create a ora service

resource "kubernetes_service" "ora-svc1" {
  metadata {
    name = "${var.name}-service"
    namespace = var.namespace
  }

  spec {
    port {
      port = 1521
      target_port = 1521
    }

    selector = local.selectors

    type = "LoadBalancer"
  }
}


# Patch Ingress map : add ora service

resource "null_resource" "patch_configmap_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch configmap ${var.ingress_mapconfig} --patch '{"data":{"1521":"default/${var.name}-service:1521"}}';
    EOT
  }
  depends_on = [
    kubernetes_service.ora-svc1
  ]
}

# Patch Ingress deployment : add ora service

resource "null_resource" "patch_deployment_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch deployment ${var.ingress_deployment} --patch "$(cat patch-ingress-nginx-deploy.yaml)";
    EOT
  }
  depends_on = [
    kubernetes_service.ora-svc1,null_resource.patch_configmap_ingress
  ]
}
resource "time_sleep" "wait_120_seconds" {
  depends_on = [kubernetes_deployment.ora-deployment]

  create_duration = "30s"
}
# Create a local variable for the load balancer ip.
locals {
  lb_ip = kubernetes_service.ora-svc1.status.0.load_balancer.0.ingress.0.ip
  lo_ip = kubernetes_service.ora-svc1.spec.0.cluster_ip
   depends_on = [
    kubernetes_service.ora-svc1,null_resource.patch_configmap_ingress,null_resource.patch_deployment_ingress
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
  value = "sonarqube"
}
# Show jdbc url for SonarQube Access for set in SonarQube Deployment
output "sonar_jdbc_url" {
  value = "jdbc:oracle:thin:@${local.lo_ip}:1521/SONARQUBE9"
}

# Show local ip address for sql server service
output "load_local_ip" {
  value = local.lo_ip
}



