variable "region" {
    description = "region to use"
    type = string
    default = "us-east-1"
  
}


variable "name" {
    description = "name to use"
    type = string
    default = "kube"
  
}

variable "node-name" {
    description = "node names to use"
    type = set(string)
    default = [ "master", "worker-1", "worker-2" ]
  
}

variable "ami" {
    description = "machine image to use"
    type = string
    default = "ami-0fc5d935ebf8bc3bc"
  
}

variable "instance-type" {
    description = "instance type to use"
    type = string
    default = "t2.medium"
  
}


variable "subnet-cidr" {
    description = "subnet cidr to use"
    type = map(string)
    default = {
      "master" =   "10.0.1.0/24",
      "worker-1" = "10.0.1.0/24",
      "worker-2" = "10.0.1.0/24",
    }
  
}