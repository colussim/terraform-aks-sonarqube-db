variable "name" {
  default     = "mssql-deployment01"
  description = "The name of the MSSQL deployment"
}
variable "namespace" {
  default     = "database02"
  description = "The kubernetes namespace to run the PMSSQL server in."
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
  default     = "pvc-mssql-data01"
  description = "The name of the PVC."
}

variable "pvc_mssql_size" {
  default     = "5Gi"
  description = "The storage size of the PVC"
}

variable "storage_class" {
  description = "The k8s storage class for the PVC used."
  default = "sonar-storage-mssql"
}

variable "mssql_image_url" {
  default = "mcr.microsoft.com/mssql/server"
  description = "The image url of the mssql version wanted"
}

variable "mssql_image_tag" {
  default = "2019-latest"
  description = "The image tag of the mssql version wanted"
}

variable "adminpassword" {
  default     = "Bench123Bench123"
  description = "user sa Password"
}

variable "sonarqubedb" {
  default     = "sonarqube9"
  description = "sonarqube database name"
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
