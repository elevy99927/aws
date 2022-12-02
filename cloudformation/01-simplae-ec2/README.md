# LAB 1: Create simple ec2 instance
Create a simple ec2 instance named: YOURNAME-ec2-01 (Ask yourself, can you add this name to your YAML File?)
Write a YAML file with the following parameters:
Type: AWS::EC2::Instance
Properties:
AZ: us-west-1a
AMI Image: (Search AMI Catalog)
Machine type: Free tier only
	OS: ubuntu 22 
	Architecture: (64-bit (x86)) 
InstanceType: t2.micro

Save the file on your local computer
On AWS web UI, Go to ‘CloudFormation -> Stacks -> Create stack’ 
Upload your YAML file
Launch a new ec2 instance

# Solution:
```
https://github.com/elevy99927/aws/blob/main/cloudformation/01-simplae-ec2/01-simaple-ec2-stack.yaml
```


# LAB 2: 
Create ec2 instance with SecurityGroups Using Ref
(REF will be explained in details later)
Create a new stack using the following template:

```
https://github.com/elevy99927/aws/blob/main/cloudformation/01-simplae-ec2/02-ecs-using-ref.yaml
```
