variable "selectors" {
  type = map(string)
  default = {}
}
variable "labels" {
  type = map(string)
  default = {}
}
variable "name" {
  default     = "sonarqube01-deployment01"
  description = "The name of the SonarQube deployment"
}
variable "namespace" {
  default     = "sonarqube"
  description = "The kubernetes namespace to run the SonarQube."
}
variable "pvcdata" {
  default     = "pvc-sonarqube-data"
  description = "The name of the PVC data."
}


variable "pvc_data_size" {
  default     = "15Gi"
  description = "The storage size of the PVC data"
}

variable "pvclogs" {
  default     = "pvc-sonarqube-logs"
  description = "The name of the PVC logs."
}

variable "pvc_logs_size" {
  default     = "1Gi"
  description = "The storage size of the PVC logs"
}


variable "pvcext" {
  default     = "pvc-sonarqube-ext"
  description = "The name of the PV extensions."
}

variable "pvc_ext_size" {
  default     = "15Gi"
  description = "The storage size of the PVC extension"
}

variable "storage_class" {
  description = "The k8s storage class for the PVC used."
  default = "sonar-class"
}

variable "sonar_image_url" {
  default = "sonarqube"
  description = "The image url of the SonarQube version wanted"
}

variable "sonar_image_tag" {
  default = "9.7.0-enterprise"
  description = "The image tag of the SonarQube version wanted"
}
variable "ingress_ns" {
  default     = "kube-system"
  description = "ingress namespace"
}

variable "ingress_mapconfig" {
  default     = "addon-http-application-routing-tcp-services"
  description = "name of ingress mapconfig"
}

variable "ingress_deployment" {
  default     = "addon-http-application-routing-nginx-ingress-controller"
  description = "name of ingress mapconfigdeployment"
}

variable "java_opt" {
  default     = "-Dbootstrap.system_call_filter=false"
  description = "SonarQube Java Addional Options"
}
variable "jdbc_user" {
  default     = "sonarqube"
  description = "User for connexion database"
}
variable "jdbc_password" {
  default     = "sonarqube"
  description = "Password User for connexion database"
}
variable "jdbc_url" {
  default     = "jdbc:oracle:thin:@10.0.138.170:1521/SONARQUBE9"
  description = "URL for connexion database"
}