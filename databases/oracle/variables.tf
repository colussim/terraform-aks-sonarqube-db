variable "name" {
  default     = "ora-deployment01"
  description = "The name of the oracle DB deployment"
}
variable "namespace" {
  default     = "database03"
  description = "The kubernetes namespace to run the oracle DB in."
}

variable "selectors" {
  type = map(string)
  default = {}
}

variable "labels" {
  type = map(string)
  default = {}
}

variable "charset" {
  default     = "AL32UTF8"
  description = "ORACLE CHARACTERSET."
}

variable "edition" {
  default     = "express"
  description = "ORACLE Edition"
}

variable "sid" {
  default     = "sonarqube9"
  description = "ORACLE SID"
}

variable "pdb" {
  default     = "sonarqube9"
  description = "ORACLE PDB"
}

variable "pvc" {
  default     = "pvc-ora-data01"
  description = "The name of the PVC Data."
}

variable "pvc-setup" {
  default     = "pvc-ora-setup"
  description = "The name of the PVC Setup : start initdb.sh script."
}


variable "pvc_ora_size" {
  default     = "10Gi"
  description = "The storage size of the PVC Data"
}

variable "pvc_ora_setup_size" {
  default     = "1Gi"
  description = "The storage size of the PVC Setup"
}
variable "pvc_ora_startup_size" {
  default     = "1Gi"
  description = "The storage size of the PVC Startup"
}

variable "storage_class" {
  description = "The k8s storage class for the PVC used."
  default = "sonar-storage-ora"
}

variable "ora_image_url" {
  default = "gvenzl/oracle-xe"
  description = "The image url of the oracle DB version wanted"
}

variable "ora_image_tag" {
  default = "latest"
  description = "The image tag of the oracle DB version wanted"
}

variable "adminpassword" {
  default     = "Bench123Bench123"
  description = "user Oracle Password"
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
