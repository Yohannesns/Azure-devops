variable "prefix" {
   description = "The prefix which should be used for all resources in this example"
   default = "UDACITY-CLI-RG"
}

variable "location" {
    description = "The Azure Region in which all resources in this example should be created."
    default ="East us"
}
variable "username" {
    description = "The username used in this example"
	default = "yoha"
}

variable "password" {
    description = "The password used in this example"
    default = "yoha1234"
}
variable "setname"{
    description = "Specifies the name of the availability set."
    default = "avset"
}
variable "vm_count" {
    description = "number of virtual machine"
    default  = 2
  }
