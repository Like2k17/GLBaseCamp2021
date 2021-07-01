variable "vms" {
  description = "zone vms"
  type        = map(any)
  default = {
    vm1 = {
      size    = "Standard_F2"
      version = "latest"
      zone    = "1"
    }
    vm2 = {
      size    = "Standard_F2"
      version = "latest"
      zone    = "2"
    }
  }
}

variable "azureuser_password" {
  default = "Password1234!"
}
