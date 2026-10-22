# 3.13 Containers – Lab 1 Solution

[⬅ Lab 1](jb-lab-1.md) | [⬅ Back to 3.13 Containers](README.md) | [Lab 2 ➡](jb-lab-2.md)

> Tested in `us-east-1` on 2 × t3.small with the ECS-optimized Amazon Linux 2023 AMI (ECS agent 1.108.0, Docker 25.0.16) and `traefik/whoami`.

**Jump to:** [Solution 1: Console](#solution-1-console-ui) · [Solution 2: AWS CLI](#solution-2-aws-cli) · [Answers](#answers) · [Solution 3: Terraform](#solution-3-terraform)

---

## Solution 1: Console (UI)

> The lab runs in **`ecs-vpc`**, the network from the [Networking lab](../2.04-vpc-and-networking/jb-lab-1.md), with the subnets `ecs-public-1a` and `ecs-public-1b`.

### Part A: Security group

The instances need a security group that lets you reach the test page on port 8080 from your own computer only.

1. Open the EC2 console: type **EC2** in the search bar at the top and choose **EC2**.

   ![Console search – EC2](images/lab1-01-search-ec2.jpg)

2. In the left menu, under **Network & Security**, choose **Security Groups**.

   ![EC2 – Network & Security – Security Groups](images/lab1-02-ec2-security-groups-nav.jpg)

3. Choose **Create security group**.

   ![Security Groups – Create security group](images/lab1-03-security-groups-list.jpg)

4. **Basic details:** Security group name **`ecs-instances-sg`**, Description **`ECS container instances`**, VPC **`ecs-vpc`**.

   ![Basic details – ecs-instances-sg, ecs-vpc](images/lab1-04-sg-basic-details.jpg)

5. **Inbound rules → Add rule:** Type **Custom TCP**, Port range **`8080`**, Source type **My IP**.

   ![Inbound rule – Custom TCP 8080 – My IP](images/lab1-05-sg-inbound-rule.jpg)

6. The source becomes your public IP address with `/32` (a single address). Leave the outbound rule (all traffic) as it is, and choose **Create security group**.

   ![Inbound rule Custom TCP 8080 from My IP – Create security group](images/lab1-06-sg-rule-create.jpg)

7. The security group has one inbound rule: TCP **8080** from your IP.

   ![ecs-instances-sg created – one inbound rule](images/lab1-07-sg-created.jpg)

### Part B: Cluster with EC2 instances

1. Open ECS: search for **ECS** and choose **Elastic Container Service**.

   ![Console search – Elastic Container Service](images/lab1-08-search-ecs.jpg)

2. **Clusters → Create cluster**.

   ![Clusters – Create cluster](images/lab1-09-ecs-clusters.jpg)

3. Cluster name **`ecs-ec2`**. Under **Infrastructure**, choose **Fargate and Self-managed instances**.

   ![Create cluster – ecs-ec2 – Fargate and Self-managed instances](images/lab1-10-create-cluster-name.jpg)

4. Auto Scaling group: **Create a new Auto Scaling group**, **On-demand**, AMI **Amazon Linux 2023**. EC2 instance type: search for and choose **t3.small**.

   ![EC2 instance type – t3.small](images/lab1-11-instance-type.jpg)

5. EC2 instance role: **Create default role** (the Console creates `ecsInstanceRole`). Desired capacity: **Minimum 2, Maximum 2**. SSH Key pair: **None**.

   ![On-demand, Amazon Linux 2023, t3.small, Create default role, 2/2, no key pair](images/lab1-12-asg-settings.jpg)

6. Expand **Network settings**. VPC: choose **`ecs-vpc`**.

   ![Network settings – VPC ecs-vpc](images/lab1-13-cluster-vpc.jpg)

7. Both subnets are selected. Security group: remove `default` and choose **`ecs-instances-sg`**.

   ![Security group – ecs-instances-sg](images/lab1-14-cluster-sg.jpg)

8. Check the network settings: VPC `ecs-vpc`, subnets in **us-east-1a** and **us-east-1b**, security group `ecs-instances-sg`, Auto-assign public IP **Turn on**.

   ![Network settings – ecs-vpc, two subnets, ecs-instances-sg, public IP on](images/lab1-15-cluster-network.jpg)

9. Choose **Create**. The note above the button explains that the Console creates a **CloudFormation stack** with the cluster, the Auto Scaling group and a **capacity provider**.

   ![Create – a CloudFormation stack builds the cluster](images/lab1-16-create-cluster-button.jpg)

10. The cluster is being created. You can continue with Part C while the instances start.

    ![Cluster ecs-ec2 creation is in progress](images/lab1-17-cluster-creating.jpg)

11. After 2–3 minutes, open **Clusters → ecs-ec2 → Infrastructure**. You see the ASG **capacity provider** and **2 container instances**, both **t3.small**, one in each Availability Zone.

    ![Infrastructure – capacity provider and 2 container instances](images/lab1-27-container-instances.jpg)

12. Open a container instance. *Agent version* and *Docker version* show the versions of the ECS agent and Docker on the instance (here **1.108.0** and **25.0.16**). Under *Resources*, a t3.small gives ECS **2,048 CPU units** and **1,913 MiB** of memory.

    ![Container instance – agent and Docker versions, CPU and memory capacity](images/lab1-28-container-instance-details.jpg)

### Part C: Task definition

1. In the ECS menu, choose **Task definitions**.

   ![ECS – Task definitions](images/lab1-18-task-definitions-nav.jpg)

2. **Create new task definition → Create new task definition**.

   ![Task definitions – Create new task definition](images/lab1-19-task-definitions.jpg)

   ![Create new task definition menu](images/lab1-20-create-task-def-menu.jpg)

3. Family **`whoami`**. Launch type: check **Amazon EC2 instances** and clear **AWS Fargate** (selected by default): Fargate supports only the `awsvpc` network mode. Network mode: **bridge**.

   ![Family whoami – EC2 instances only – network mode bridge](images/lab1-21-task-def-family-network.jpg)

4. Task size: CPU **`.25 vCPU`**, Memory **`.5 GB`**. Task execution role: **None** (the image is public and we don't send logs).

   ![Task size .25 vCPU / .5 GB – Task execution role None](images/lab1-22-task-size-role.jpg)

5. **Container – 1:** Name **`whoami`**, Image URI **`traefik/whoami`**, port mapping **Host port `8080`**, **Container port `80`**.

   ![Container whoami – traefik/whoami – 8080 → 80](images/lab1-23-container.jpg)

6. **Logging:** clear **Use log collection** (it needs CloudWatch Logs and an execution role).

   ![Clear Use log collection](images/lab1-24-log-collection.jpg)

7. Choose **Create**.

   ![Create task definition](images/lab1-25-create-task-def-button.jpg)

8. The task definition **`whoami:1`** shows **Task CPU 256 units (0.25 vCPU)**, **Task memory 512 MiB**, network mode **bridge**, and no execution role.

   ![whoami:1 – 256 CPU units, 512 MiB, bridge](images/lab1-26-task-def-created.jpg)

> While **AWS Fargate** is still selected, CPU and memory are lists that start at **.25 vCPU** and **.5 GB**, the smallest Fargate size. We use that size here, so the same values work whether or not Fargate is selected.

**How many tasks fit on an instance?** ECS places a task only on an instance with enough **free** CPU and memory. A t3.small gives ECS **2,048 CPU units** and **1,913 MiB** (the rest of its 2 GiB is for the OS and the ECS agent), so up to **3** of these tasks fit by memory (3 × 512 MiB). On a t3.micro (916 MiB) only one would fit, and Lab 2 needs two per instance.

### Part D: Service

1. Open **Clusters → ecs-ec2 → Services** and choose **Create**.

   ![ecs-ec2 – Services – Create](images/lab1-29-services-create.jpg)

2. Task definition family: **`whoami`** (revision: latest).

   ![Task definition family whoami](images/lab1-30-service-family.jpg)

3. Service name **`whoami-svc`**. Compute options: **Launch type**, then Launch type **EC2**.

   ![whoami-svc – Launch type – EC2](images/lab1-31-service-details.jpg)

4. Scheduling strategy **Replica**, Desired tasks **2**.

   ![Launch type EC2 – Replica – Desired tasks 2](images/lab1-32-service-launch-desired.jpg)

5. Scroll down and choose **Create**. No load balancer in this lab.

   ![Create service](images/lab1-33-create-service-button.jpg)

6. After about a minute, the **Tasks** tab shows **2 tasks** *Running*, one on each instance. With a static host port, there can't be two on the same instance.

   ![Tasks – 2 running](images/lab1-34-tasks-running.jpg)

### Part E: Test

Find the public IPs in **EC2 → Instances** (*Public IPv4 address* column):

![EC2 Instances – public IPv4 addresses](images/lab1-35-instances-public-ip.jpg)

Open `http://<public-ip-of-instance>:8080` for each instance:

```
Hostname: bba19f30b71b
IP: 127.0.0.1
IP: 172.17.0.2
RemoteAddr: <your-ip>:50287
GET / HTTP/1.1
Host: <public-ip>:8080
...
```

- **`Hostname`** is the **container ID**, which is different on each instance.
- **`IP: 172.17.0.2`** is the container's address on the Docker **bridge** network inside the instance, which is why the network mode is called `bridge`.

### Part F: Self-healing and the static port limit

**8. Stop a task.**

1. In **Tasks**, select one task → **Stop → Stop selected**.

   ![Tasks – Stop selected](images/lab1-36-stop-task.jpg)

2. Confirm with **Stop**.

   ![Stop task – confirm](images/lab1-37-stop-task-confirm.jpg)

3. Within seconds, the service starts a replacement, because desired = 2. **Services → whoami-svc → Events** shows *"has started 1 tasks"*.

   ![Events – has started 1 tasks](images/lab1-38-self-healing-event.jpg)

**9. Desired tasks = 3.**

1. Choose **Update service**.

   ![whoami-svc – Update service](images/lab1-39-update-service.jpg)

2. Desired tasks **3**.

   ![Desired tasks 3](images/lab1-40-desired-3.jpg)

3. Choose **Update**.

   ![Update](images/lab1-41-update-button.jpg)

4. The service stays at **2 running**, and the **Events** tab explains why:

   ![Events – unable to place a task: port already in use](images/lab1-42-port-limit-event.jpg)

> *service whoami-svc was unable to place a task because no container instance met all of its requirements. The closest matching container-instance … is already using a port required by your task.*

Both instances already use host port **8080**, so there's nowhere to put a third task. CPU and memory aren't the problem: each instance still had **1,792 CPU units** and **1,401 MiB** free. **10.** Set desired tasks back to **2** (Update service again).

### Part G: Clean up or continue

Continuing to Lab 2? Keep the cluster. Otherwise:

1. **Services → whoami-svc → Delete service.**

   ![whoami-svc – Delete service](images/lab1-43-delete-service.jpg)

   Check **Force delete** (it scales the service to zero for you), type `delete`, and choose **Delete**.

   ![Delete service – Force delete](images/lab1-44-delete-service-confirm.jpg)

2. **Clusters → ecs-ec2 → Actions → Delete cluster.**

   ![Actions – Delete cluster](images/lab1-45-delete-cluster.jpg)

   Type `delete ecs-ec2` and choose **Delete**. This also deletes the CloudFormation stack, the Auto Scaling group and its instances.

   ![Delete cluster – also deletes the CloudFormation stack](images/lab1-46-delete-cluster-confirm.jpg)

3. **Task definitions → whoami →** select `whoami:1` → **Actions → Deregister**.

   ![Actions – Deregister](images/lab1-47-deregister-task-def.jpg)

   ![Deregister – confirm](images/lab1-48-deregister-confirm.jpg)

   Then **Filter status: Inactive** → select `whoami:1` → **Actions → Delete**, type `delete`, and choose **Delete**.

   ![Inactive – Actions – Delete](images/lab1-49-delete-task-def.jpg)

   ![Delete task definition – confirm](images/lab1-50-delete-task-def-confirm.jpg)

4. **EC2 → Security groups →** select `ecs-instances-sg` → **Actions → Delete security groups**, after the instances have terminated.

   ![Actions – Delete security groups](images/lab1-51-delete-sg.jpg)

   ![Delete security groups – confirm](images/lab1-52-delete-sg-confirm.jpg)

5. Keep the network (`ecs-vpc`): the next labs use it.

---

## Solution 2: AWS CLI

The CLI builds the same thing piece by piece: an instance role, an empty cluster, a launch template with the ECS-optimized AMI, and an Auto Scaling Group. The ECS agent on each instance registers it to the cluster, using the **user data** line `ECS_CLUSTER=ecs-ec2`.

```bash
export AWS_PAGER="" AWS_REGION=us-east-1
MY_IP=$(curl -s https://checkip.amazonaws.com)
VPC_ID=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)
SUBNET_A=$(aws ec2 describe-subnets --filters Name=default-for-az,Values=true Name=availability-zone,Values=us-east-1a --query 'Subnets[0].SubnetId' --output text)
SUBNET_B=$(aws ec2 describe-subnets --filters Name=default-for-az,Values=true Name=availability-zone,Values=us-east-1b --query 'Subnets[0].SubnetId' --output text)

# Part A: security group
INST_SG=$(aws ec2 create-security-group --group-name ecs-instances-sg \
  --description "ECS container instances" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $INST_SG --protocol tcp --port 8080 --cidr $MY_IP/32

# Part B: instance role (the ECS agent uses it to register the instance)
cat > ec2-trust.json <<'JSON'
{ "Version": "2012-10-17", "Statement": [{ "Effect": "Allow", "Principal": { "Service": "ec2.amazonaws.com" }, "Action": "sts:AssumeRole" }] }
JSON
aws iam create-role --role-name ecsInstanceRole --assume-role-policy-document file://ec2-trust.json
aws iam attach-role-policy --role-name ecsInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
aws iam create-instance-profile --instance-profile-name ecsInstanceRole
aws iam add-role-to-instance-profile --instance-profile-name ecsInstanceRole --role-name ecsInstanceRole

# Part B: cluster + launch template (ECS-optimized AMI) + Auto Scaling Group
aws ecs create-cluster --cluster-name ecs-ec2
AMI_ID=$(aws ssm get-parameter --name /aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id \
  --query Parameter.Value --output text)
UD=$(printf '#!/bin/bash\necho ECS_CLUSTER=ecs-ec2 >> /etc/ecs/ecs.config\n' | base64 | tr -d '\n')
cat > lt.json <<JSON
{ "ImageId": "$AMI_ID", "InstanceType": "t3.small",
  "IamInstanceProfile": { "Name": "ecsInstanceRole" },
  "NetworkInterfaces": [{ "DeviceIndex": 0, "AssociatePublicIpAddress": true, "Groups": ["$INST_SG"] }],
  "UserData": "$UD",
  "TagSpecifications": [{ "ResourceType": "instance", "Tags": [{ "Key": "Name", "Value": "ecs-instance" }] }] }
JSON
sleep 10   # let the new instance profile propagate
aws ec2 create-launch-template --launch-template-name ecs-lt --launch-template-data file://lt.json
aws autoscaling create-auto-scaling-group --auto-scaling-group-name ecs-asg \
  --launch-template LaunchTemplateName=ecs-lt,Version='$Latest' \
  --min-size 2 --max-size 2 --desired-capacity 2 --vpc-zone-identifier "$SUBNET_A,$SUBNET_B"
```

**Step 3: wait for the instances to register:**

```bash
aws ecs describe-container-instances --cluster ecs-ec2 \
  --container-instances $(aws ecs list-container-instances --cluster ecs-ec2 --query containerInstanceArns --output text) \
  --query 'containerInstances[].[ec2InstanceId,status,versionInfo.agentVersion,versionInfo.dockerVersion,registeredResources[?name==`CPU`].integerValue|[0],registeredResources[?name==`MEMORY`].integerValue|[0]]' --output table
```

```
|  i-068fd3af5bed2744a |  ACTIVE |  1.108.0 |  DockerVersion: 25.0.16  |  2048 |  1913 |
|  i-0d54c013a83b02d79 |  ACTIVE |  1.108.0 |  DockerVersion: 25.0.16  |  2048 |  1913 |
```

The last two columns are the CPU units and the memory (MiB) that each instance gives ECS for tasks.

**Parts C–D: task definition and service:**

```bash
cat > td-whoami.json <<'JSON'
{
  "family": "whoami",
  "networkMode": "bridge",
  "requiresCompatibilities": ["EC2"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "whoami",
    "image": "traefik/whoami",
    "essential": true,
    "portMappings": [{ "containerPort": 80, "hostPort": 8080, "protocol": "tcp" }]
  }]
}
JSON
aws ecs register-task-definition --cli-input-json file://td-whoami.json

aws ecs create-service --cluster ecs-ec2 --service-name whoami-svc \
  --task-definition whoami --desired-count 2 --launch-type EC2
aws ecs wait services-stable --cluster ecs-ec2 --services whoami-svc
```

**Part E: test:**

```bash
for IP in $(aws ec2 describe-instances --filters Name=tag:Name,Values=ecs-instance \
    Name=instance-state-name,Values=running --query 'Reservations[].Instances[].PublicIpAddress' --output text); do
  curl -s http://$IP:8080 | head -3; echo ---
done
```

**Part F: self-healing and the placement failure:**

```bash
T=$(aws ecs list-tasks --cluster ecs-ec2 --service-name whoami-svc --query 'taskArns[0]' --output text)
aws ecs stop-task --cluster ecs-ec2 --task $T --reason "testing self-healing"

aws ecs update-service --cluster ecs-ec2 --service whoami-svc --desired-count 3
sleep 60
aws ecs describe-services --cluster ecs-ec2 --services whoami-svc \
  --query 'services[0].[desiredCount,runningCount]' --output text          # 3   2
aws ecs describe-services --cluster ecs-ec2 --services whoami-svc \
  --query 'services[0].events[0].message' --output text
aws ecs update-service --cluster ecs-ec2 --service whoami-svc --desired-count 2
```

**Part G: clean up** (if you're not continuing to Lab 2):

```bash
aws ecs delete-service --cluster ecs-ec2 --service whoami-svc --force
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name ecs-asg --force-delete
aws ecs delete-cluster --cluster ecs-ec2
aws ec2 delete-launch-template --launch-template-name ecs-lt
until aws ec2 delete-security-group --group-id $INST_SG 2>/dev/null; do sleep 10; done   # waits for the instances
aws ecs deregister-task-definition --task-definition whoami:1
aws ecs delete-task-definitions --task-definitions whoami:1
aws iam remove-role-from-instance-profile --instance-profile-name ecsInstanceRole --role-name ecsInstanceRole
aws iam delete-instance-profile --instance-profile-name ecsInstanceRole
aws iam detach-role-policy --role-name ecsInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role
aws iam delete-role --role-name ecsInstanceRole
```

---

## Answers

- **Task definition vs. task vs. service:** the **task definition** is the blueprint (JSON, versioned). A **task** is a running copy of it. A **service** keeps a desired number of tasks running, replaces failed ones, and can connect them to a load balancer.
- **Who registered the instances:** the **ECS agent** on each instance. It reads the cluster name from `/etc/ecs/ecs.config` (written by the user data) and calls ECS with the permissions of the **instance role** (`AmazonEC2ContainerServiceforEC2Role`).
- **Why the third task couldn't start:** both instances already use **host port 8080**, and a port can be bound only once per instance. There was enough CPU and memory left for another task; only the port was missing. You could add instances, or better, use **dynamic host ports** behind a load balancer, which is Lab 2.
- **S3 access for the container:** the **task role** (`taskRoleArn`). Not the instance role, which every task on the instance would share, and not the execution role, which ECS uses only to pull images and send logs.

---

[⬅ Lab 1](jb-lab-1.md) | [⬅ Back to 3.13 Containers](README.md) | [Lab 2 ➡](jb-lab-2.md)

---

## Solution 3: Terraform

[`terraform/jb-lab-1/main.tf`](terraform/jb-lab-1/main.tf) builds the whole lab: the security group, the instance role, the cluster, a launch template with the ECS-optimized AMI (from the public SSM parameter), the Auto Scaling Group, the task definition and the service.

```bash
cd terraform/jb-lab-1
terraform init
terraform apply -var my_ip_cidr="$(curl -s https://checkip.amazonaws.com)/32"   # about 1 minute
for IP in $(eval "$(terraform output -raw find_instance_ips)"); do curl -s http://$IP:8080 | grep Hostname; done
terraform destroy -var my_ip_cidr="0.0.0.0/32"                                   # about 3 minutes
```

The tested run (2 × t3.small): `apply` took 38 s, both tasks answered about 45 s later, and `destroy` took 186 s:

```
Hostname: 6f7bb6d7d042
Hostname: 19314b929713
```

> The Terraform code names the instance role `ecs-instance-role`, so it doesn't collide with the `ecsInstanceRole` that the Console creates.
>
> The service has `depends_on = [..., aws_iam_role_policy_attachment.instance]`, so `destroy` deletes the service **before** it removes the instance role's policy. Without it, Terraform can remove the policy first. The ECS agent on the instances then loses its permissions (`agentConnected: false`), the tasks can never report that they stopped, and the service hangs in **DRAINING**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
