locals {
  labels = merge(var.labels, {
    app = "sonarqube"
    deploymentName = var.name
  })

  selectors = merge(var.selectors, {
    app = "sonarqube"
    deploymentName = var.name
  })
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
       # key = "failure-domain.beta.kubernetes.io/zone"
       # values = ["westeurope-1","westeurope-2"]
        key = "topology.disk.csi.azure.com/zone"
        values = ["westeurope-1"]
    }  

  }  
}

# create a namespace
resource "kubernetes_namespace" "sonarqube-namespace" {
  metadata {
    name = var.namespace
  }
}

# create a config map
resource "kubernetes_config_map" "sonarqube-config" {
  metadata {
    name = "sonarqube-config"
    namespace= var.namespace
  }

  data = {

  SONAR_SEARCH_JAVAADDITIONALOPTS=var.java_opt
  SONARQUBE_JDBC_USERNAME=var.jdbc_user
  SONARQUBE_JDBC_PASSWORD=var.jdbc_password
  SONARQUBE_JDBC_URL=var.jdbc_url
  }
  depends_on = [
  kubernetes_namespace.sonarqube-namespace
  ]
}

# create a PVC for data (Persistent volume Claim)

resource "kubernetes_persistent_volume_claim" "data-pvc" {
  metadata {
    name = var.pvcdata
    namespace = var.namespace
  }
  
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.pvc_data_size
      }
    }
  }
  depends_on = [
  kubernetes_namespace.sonarqube-namespace,kubernetes_storage_class.sonarclass
  ]
  
}
# create a PVC for logs (Persistent volume Claim)

resource "kubernetes_persistent_volume_claim" "logs-pvc" {
  metadata {
    name = var.pvclogs
    namespace = var.namespace
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
    resources {
      requests = {
        storage = var.pvc_logs_size
      }
    }
  }
  depends_on = [
  kubernetes_namespace.sonarqube-namespace,kubernetes_storage_class.sonarclass
  ]
}
# create a PVC for extensions (Persistent volume Claim)

resource "kubernetes_persistent_volume_claim" "ext-pvc" {
  metadata {
    name = var.pvcext
    namespace = var.namespace
  }
  spec {
    storage_class_name = var.storage_class
    access_modes = [
      "ReadWriteOnce"
    ]
  
    resources {
      requests = {
        storage = var.pvc_ext_size
      }
   }
  }
 depends_on = [
  kubernetes_namespace.sonarqube-namespace,kubernetes_storage_class.sonarclass
  ]
}

# create a SonarQube Deployment
 
resource "kubernetes_deployment" "sonarqube-deployment" {
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
        name = "sonarqube"
        labels = local.labels
      }

      spec {   
           security_context {
           
           run_as_user=1000
           run_as_group = 1000
           } 
 
 # init kernel Parameters
        init_container {
          name  = "sonarqube-es-init"
          image = "busybox:1.32" 
          command = ["/bin/sh", "-c", "sysctl -w vm.max_map_count=262144"]
          image_pull_policy="IfNotPresent"
          security_context {
               privileged=true
               run_as_user= 0
          } 
        }
# init FS Privilege
        init_container {
          name  = "sonarqube-es-init2"
          image = "busybox:1.32" 
          command = ["/bin/sh", "-c", "mkdir -p /opt/sonarqube/extensions/jdbc-driver/oracle && wget -O /opt/sonarqube/extensions/jdbc-driver/oracle/ojdbc11.jar  https://download.oracle.com/otn-pub/otn_software/jdbc/217/ojdbc11.jar && chown -R 1000:1000 /opt/sonarqube/extensions && chmod -R 777 /opt/sonarqube/extensions"]
          image_pull_policy="IfNotPresent"
          security_context {
               privileged=true
               run_as_user= 0
          } 
          volume_mount {
            mount_path = "/opt/sonarqube/extensions"
            name = "sonarqube-extensions"
          }
           
        }

        init_container {
          name  = "sonarqube-es-init3"
          image = "busybox" 
          command = ["/bin/sh", "-c", "chown -R 1000:1000 /opt/sonarqube/data && chmod -R 777 /opt/sonarqube/data"]
          image_pull_policy="IfNotPresent"
          security_context {
               privileged=true
               run_as_user= 0
          } 
          volume_mount {
            mount_path = "/opt/sonarqube/data"
            name = "sonarqube-data"
          }
           
        }

        init_container {
          name  = "sonarqube-es-init4"
          image = "busybox" 
          command = ["/bin/sh", "-c", "chown -R 1000:1000 /opt/sonarqube/logs && chmod -R 777 /opt/sonarqube/logs"]
          image_pull_policy="IfNotPresent"
          security_context {
               privileged=true
               run_as_user= 0
          } 
          volume_mount {
            mount_path = "/opt/sonarqube/logs"
            name = "sonarqube-logs"
          }
           
        }

       container {
          name = "sonarqube"
          image = "${var.sonar_image_url}:${var.sonar_image_tag}"
          image_pull_policy="IfNotPresent"
          port {
            container_port = 9000
          }

          volume_mount {
            mount_path = "/opt/sonarqube/data"
            name = "sonarqube-data"
          }
          volume_mount {
            mount_path = "/opt/sonarqube/logs"
            name = "sonarqube-logs"
          }  
           volume_mount {
            mount_path = "/opt/sonarqube/extensions"
            name = "sonarqube-extensions"
          }
           env_from {
            config_map_ref {
               name ="sonarqube-config"

             }
           }  
            
          security_context {
            privileged=true
            run_as_user=1000
            run_as_group = 1000
          
           } 
           
        }
        
        volume {
          name = "sonarqube-data"
          persistent_volume_claim {
            claim_name = var.pvcdata 
          }
        }
        volume {
          name = "sonarqube-logs"
          persistent_volume_claim {
            claim_name = var.pvclogs 
          }
        }
        volume {
          name = "sonarqube-extensions"
          persistent_volume_claim {
            claim_name = var.pvcext 
          }
        }  
        
          
      }
    }
  }
  
  depends_on = [
  kubernetes_namespace.sonarqube-namespace,kubernetes_config_map.sonarqube-config,kubernetes_persistent_volume_claim.data-pvc,kubernetes_persistent_volume_claim.logs-pvc,
  kubernetes_persistent_volume_claim.ext-pvc
  ]
}


# Create a service for SonarQube
resource "kubernetes_service" "sonarqube-svc1" {
  metadata {
    name = "${var.name}-service"
    namespace = var.namespace
  }

  spec {
    port {
      port = 9000
      target_port = 9000
    }

    selector = local.selectors

    type = "LoadBalancer"
  }
  depends_on = [
    kubernetes_namespace.sonarqube-namespace
  ]
}

# Patch Ingress map : add SonarQube service

resource "null_resource" "patch_configmap_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch configmap ${var.ingress_mapconfig} --patch '{"data":{"9000":"default/${var.name}-service:9000"}}';
    EOT
  }
  depends_on = [
    kubernetes_service.sonarqube-svc1
  ]
}

# Patch Ingress deployment : add SonarQube service

resource "null_resource" "patch_deployment_ingress" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
    kubectl -n ${var.ingress_ns} patch deployment ${var.ingress_deployment} --patch "$(cat patch-ingress-nginx-deploy.yaml)";
    EOT
  }
  depends_on = [
    kubernetes_service.sonarqube-svc1,null_resource.patch_configmap_ingress
  ]
}

# Create a local variable for the load balancer ip.
locals {
  lb_ip = kubernetes_service.sonarqube-svc1.status.0.load_balancer.0.ingress.0.ip

   depends_on = [
    kubernetes_service.sonarqube-svc1,null_resource.patch_configmap_ingress,null_resource.patch_deployment_ingress
  ]
}

# Show SonarQube URL access
output "load_balancer_ip" {
  value = "SonarQube URL Access : http://${local.lb_ip}:9000"
}
