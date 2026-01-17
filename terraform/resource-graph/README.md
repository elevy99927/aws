# Resource Graph


## Example Code

```hcl

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

```


```mermaid
graph TD
    VPC[aws_vpc.main]

    IGW[aws_internet_gateway.igw]
    SUBNET[aws_subnet.public]
    RT[aws_route_table.public]

    ROUTE[aws_route.default_route]

    VPC --> IGW
    VPC --> SUBNET
    VPC --> RT

    IGW --> ROUTE
    RT --> ROUTE
```
