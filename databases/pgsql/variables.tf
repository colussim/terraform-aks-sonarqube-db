variable "name" {
  default     = "pgsql-deployment02"
  description = "The name of the PostgreSQL deployment"
}
variable "namespace" {
  default     = "database01"
  description = "The kubernetes namespace to run the PostgreSQL server in."
}

variable "selectors" {
  type = map(string)
  default = {}
}

variable "labels" {
  type = map(string)
  default = {}
}

variable "pvc" {
  default     = "pvc-pgsql-data01"
  description = "The name of the PVC."
}

variable "pvc_pgsql_size" {
  default     = "5Gi"
  description = "The storage size of the PVC"
}

variable "storage_class" {
  description = "The k8s storage class for the PVC used."
  default = "managed-csi"
}

variable "pgsql_image_url" {
  default = "postgres"
  description = "The image url of the pgsql version wanted"
}

variable "pgsql_image_tag" {
  default = "13.8"
  description = "The image tag of the pgsql version wanted"
}

variable "adminpassword" {
  default     = "Bench123"
  description = "PGSQL Admin password"
}

variable "databasename" {
  default     = "sonarqube9"
  description = "Database Name"
}

variable "sonarusers" {
  default     = "sonarqube"
  description = "Sonar user login in Database"
}

variable "sonarpass" {
  default     = "sonarqube"
  description = "Sonar user password in Database"
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

