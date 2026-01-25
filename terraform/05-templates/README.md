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
