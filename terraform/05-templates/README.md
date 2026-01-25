
# Terraform Templates

## Task: 
You need to connect your `web-server` to the `database`. 
<BR>You can do it using `user-data`.
<BR>ßHowever, you don’t know the IP address of your database server..

Use the example in slide 21 to create the following:
- Web server 
- Database server
- Use `template_file` to save database IP in the `web-server` `user-data` file

Use the example files from:
**[05-templates](https://github.com/elevy99927/aws/tree/main/terraform/05-templates)**

Advance Reading:
https://developer.hashicorp.com/terraform/language/functions/templatefile


## Fix the error:

### Error 1:
fix `web.tf`

```java
"launch_template": one of `ami,instance_type,launch_template` must be specified
"ami": one of `ami,launch_template` must be specified
"instance_type": one of `instance_type,launch_template` must be specified

```


---

### Error 2:
```java
Provider "registry.terraform.io/hashicorp/aws" requires explicit configuration.
Add a provider block to the root module
```


**[Solution](https://github.com/elevy99927/aws/blob/main/terraform/05-templates/SOLUTION.md)**
