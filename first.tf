
variable "user" {
  type = string
  }
variable age {
  type = number
  }

output details {
  
  value ="my name is ${var.user} and my age is ${var.age} "
}