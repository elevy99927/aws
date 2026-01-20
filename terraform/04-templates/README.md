fix the error:

```bash

$ terraform plan
╷
│ Error: Missing required argument
│ 
│   with aws_instance.web,
│   on web.tf line 1, in resource "aws_instance" "web":
│    1: resource "aws_instance" "web" {
│ 
│ "ami": one of `ami,launch_template` must be specified
╵
╷
│ Error: Missing required argument
│ 
│   with aws_instance.web,
│   on web.tf line 1, in resource "aws_instance" "web":
│    1: resource "aws_instance" "web" {
│ 
│ "instance_type": one of `instance_type,launch_template` must be specified
╵
╷
│ Error: Missing required argument
│ 
│   with aws_instance.web,
│   on web.tf line 1, in resource "aws_instance" "web":
│    1: resource "aws_instance" "web" {
│ 
│ "launch_template": one of `ami,instance_type,launch_template` must be specified
╵
```
