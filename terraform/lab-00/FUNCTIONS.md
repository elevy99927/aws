# Terraform functions:

### Part 1 - Functions (slid 26):
- list
- slice
- length

`vars.tf`
```hcl
variable "availability_zone_names" {
  type    = list(string)
  default = ["us-west-1a", "us-west-1b", "us-west-1c"]
}

```

**Task:**
- Print first 2 AZ
- Print AZ count
- Print the last AZ

---
### Part 2 - Functions:
- upper
- length
- contains


**Input data:**
`vars.tf`
```hcl
variable "env" {
  type    = string
  default = "prod"
}

variable "regions" {
  type    = list(string)
  default = ["us-east-1", "eu-west-1", "ap-south-1"]
}
```



**Task:**
- Print the value of env in uppercase
- Print the number of regions
- Check is the list of regions contains “eu-west-1”









---







**Lab 3 Solution:**
```BASH
⁠> upper(var.env)
"PROD"
> ⁠length(var.regions)
3
> ⁠contains(var.regions, "eu-west-1")
true
```
