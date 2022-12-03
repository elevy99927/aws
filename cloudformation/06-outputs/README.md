# Lab 6: CloudFormation outputs
1. Create a new SecurityGroup named: 'YOURNAME-ssh-sg-01'
use the following YAML example for your SG:
```
Resources:
 MySSHSecurityGroup:
   Type: AWS::EC2::SecurityGroup
   Properties:
     GroupDescription: Enable SSH access via port 22
     SecurityGroupIngress:
     - CidrIp: 0.0.0.0/0
       FromPort: 22
       IpProtocol: tcp
       ToPort: 22
Outputs:
 StackSSHSecurityGroup:
   Description: The SSH Security Group for our Company
   Value: !Ref MySSHSecurityGroup
   Export:
     Name: SSHSecurityGroup
```

2. Create a new EC2 instance name: YOURNAME-ec2-ssh-01

## Reference:
<a href="http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html">http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-security-group.html</a>
<a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html">https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html</a>

## Solution:
<a href="https://github.com/elevy99927/aws/tree/main/cloudformation/06-outputs">https://github.com/elevy99927/aws/tree/main/cloudformation/06-outputs</a>
