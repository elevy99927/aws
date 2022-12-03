# LAB 1: Using Parameters
Create a CF template with the following parameters:

### Instance name: String

### Ssh-key: Dropbox
Select from existing keyPairs (you will need to create a key befor)

### Instance type: Dropbox
Select from the following options: t1.micro, t2.nana, t2.micro

```
At this point, you will not be able to connect to your instance using ssh.
Inorder to connect to your server, You will need to create a SecurityGroup manualy
```

## Reference:
<A href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html">https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html</a>

## Solution:
<a href="https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/01-ec2-with-parametes.yaml">https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/01-ec2-with-parametes.yaml</a>

# LAB 2: Additional example of using Parameters

<a href="https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/02-ec2-with-more-parametes.yaml">https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/02-ec2-with-more-parametes.yaml</a>

# LAB 3: Create EC2 using SSM
On AWS Systems Manager -> Parameter Store, create 2 parameters:
1. Private parameter 
name: /dev/ec2/instanceType 
value: t2.micro
2. Public Parameter:
type: ami-amazon-linux-latest
value: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 
3. create a simple ec2 instance, using t2.micro and ami-amazon-linux-latest image, from your parameters.

## Solution
<a href="https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/03-simple-ec2-with-ssm.yaml">https://github.com/elevy99927/aws/blob/main/cloudformation/03-parameters/03-simple-ec2-with-ssm.yaml</a>