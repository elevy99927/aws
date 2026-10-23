# 3.06 Containers – Lab 3 Solution

[⬅ Lab 3](jb-lab-3.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 4 ➡](jb-lab-4.md)

> Tested in `us-east-1`, in `ecs-vpc` from the [Networking lab](../2.04-vpc-and-networking/lab-1.md). The service had 2 running tasks **82 seconds** after it was created, and scaling from 2 to 4 tasks took about **35 seconds**.

**Jump to:** [Solution 1: Console](#solution-1-console-ui) · [Solution 2: AWS CLI](#solution-2-aws-cli) · [Answers](#answers) · [Solution 3: Terraform](#solution-3-terraform)

---

## Solution 1: Console (UI)

### Part A: A Fargate-only cluster

On Fargate, a cluster is only a name that groups your services and tasks. There are no servers to choose or size.

1. **ECS → Clusters → Create cluster**.

   ![ECS Clusters – Create cluster](images/fargate-01-create-cluster.jpg)

2. Cluster name **`ecs-fargate`**. Under *Infrastructure*, keep **Fargate only** (the default).

   ![Cluster name ecs-fargate, Fargate only](images/fargate-02-cluster-name-fargate-only.jpg)

3. Scroll down and choose **Create**.

   ![Create cluster – Create](images/fargate-03-create-cluster-button.jpg)

4. The cluster is ready within seconds, with **0 EC2** container instances.

   ![Cluster ecs-fargate created – 0 EC2 instances](images/fargate-04-cluster-created.jpg)

### Part B: A Fargate task definition

The task definition is the blueprint: which image to run, how much CPU and memory it gets, and which port it listens on.

5. Open the side menu and choose **Task definitions**.

   ![Side menu – Task definitions](images/fargate-05-task-definitions-nav.jpg)

6. Choose **Create new task definition**.

   ![Create new task definition](images/fargate-06-create-task-definition.jpg)

7. Task definition family **`whoami-fargate`**. Launch type **AWS Fargate** is already selected.

   ![Family whoami-fargate, launch type AWS Fargate](images/fargate-07-td-family-launch-type.jpg)

8. Under *Task size*, open **CPU** and choose **.25 vCPU**.

   ![CPU – .25 vCPU](images/fargate-08-td-cpu.jpg)

9. Memory changes to **.5 GB** on its own, the smallest size that fits .25 vCPU. *Task execution role*: keep **Create default role**. The Console creates **`ecsTaskExecutionRole`**, which ECS uses to pull the image and write logs. The network mode is fixed to `awsvpc`.

   ![Task size .25 vCPU / .5 GB, task execution role Create default role](images/fargate-09-td-size-execution-role.jpg)

10. Under *Container – 1*: name **`whoami`**, image URI **`traefik/whoami`**, container port **80** (the default).

   ![Container whoami, image traefik/whoami, port 80](images/fargate-10-td-container.jpg)

11. *Environment variables* → **Add environment variable**: `WHOAMI_NAME` = `fargate`. Under *Logging*, clear **Use log collection**, as in Lab 1, so there's no log group to clean up.

   ![WHOAMI_NAME = fargate, Use log collection cleared](images/fargate-11-td-env-logging.jpg)

12. Scroll down and choose **Create**.

   ![Create task definition – Create](images/fargate-12-td-create-button.jpg)

13. The task definition is created: *App environment* **Fargate**, *Network mode* **awsvpc**, and the new **`ecsTaskExecutionRole`**.

   ![whoami-fargate created – Fargate, awsvpc, ecsTaskExecutionRole](images/fargate-13-td-created.jpg)

> The revision number keeps growing for a family, even after you delete its revisions. Here it's `:2` because the family existed before. Yours is probably `:1`.

### Part C: A security group for the tasks

With `awsvpc`, every task has its **own** network interface, so the security group protects each task directly, not a server.

14. Open **EC2** (from the favorites bar or the search box).

   ![Favorites bar – EC2](images/fargate-14-open-ec2.jpg)

15. In the side menu, under *Network & Security*, choose **Security Groups**.

   ![EC2 – Security Groups](images/fargate-15-security-groups-nav.jpg)

16. Choose **Create security group**.

   ![Create security group](images/fargate-16-create-security-group.jpg)

17. Name **`fargate-tasks-sg`**, description `Fargate tasks - HTTP from my IP`, and VPC **`ecs-vpc`**.

   ![Name fargate-tasks-sg, VPC ecs-vpc](images/fargate-17-sg-basic-details.jpg)

18. *Inbound rules* → **Add rule**: Type **HTTP**, Source type **My IP**.

   ![Inbound rule – HTTP, source type My IP](images/fargate-18-sg-source-my-ip.jpg)

19. The rule allows port **80** only from your own address (`/32`).

   ![Inbound rule HTTP 80 from my IP /32](images/fargate-19-sg-inbound-rule.jpg)

20. Scroll down and choose **Create security group**.

   ![Create security group – button](images/fargate-20-sg-create-button.jpg)

21. The group is created with one inbound rule.

   ![fargate-tasks-sg – HTTP 80 from my IP](images/fargate-21-sg-created.jpg)

### Part D: Service

The service keeps **2** copies of the task running, and replaces any copy that stops.

22. Back in **ECS → Clusters**, open **`ecs-fargate`**.

   ![Clusters – ecs-fargate](images/fargate-22-open-cluster.jpg)

23. On the *Services* tab, choose **Create**.

   ![Services – Create](images/fargate-23-create-service.jpg)

24. Task definition family **`whoami-fargate`** (the latest revision is selected), service name **`whoami-fargate-svc`**.

   ![Family whoami-fargate, service name whoami-fargate-svc](images/fargate-24-svc-family-name.jpg)

25. *Compute configuration*: keep the default capacity provider **FARGATE**. It places the tasks on Fargate (choosing *Launch type → FARGATE* does the same).

   ![Capacity provider FARGATE](images/fargate-25-svc-capacity-provider.jpg)

26. *Deployment configuration*: **Desired tasks 2**.

   ![Desired tasks 2](images/fargate-26-svc-desired-tasks.jpg)

27. Expand *Networking* and choose the VPC **`ecs-vpc`**.

   ![Networking – VPC ecs-vpc](images/fargate-27-svc-vpc.jpg)

28. Both subnets of `ecs-vpc` are selected. Under *Security group*, remove `default` and choose **`fargate-tasks-sg`**.

   ![Security group – fargate-tasks-sg](images/fargate-28-svc-security-group.jpg)

29. Check the networking: **`ecs-public-1a`** and **`ecs-public-1b`** (two Availability Zones), **`fargate-tasks-sg`**, and **Public IP: Turned on**.

   ![Subnets ecs-public-1a/1b, fargate-tasks-sg, public IP on](images/fargate-29-svc-networking.jpg)

   > Without a public IP, a task in a public subnet can't reach Docker Hub to pull `traefik/whoami`, and you can't reach it from your browser.

30. Leave *Load balancing* empty (a later lab adds a load balancer) and choose **Create**.

   ![Create service – Create](images/fargate-30-svc-create-button.jpg)

31. About a minute later the service shows **2/2 Tasks running**, and *Registered container instances* is empty (`-`): there are no servers.

   ![whoami-fargate-svc – 2/2 tasks running, no container instances](images/fargate-31-service-running.jpg)

### Part E: Test and explore

32. Open the **Tasks** tab: two tasks, and the *Container instance* column is `-`. Open the first task.

   ![Tasks tab – 2 running Fargate tasks](images/fargate-32-tasks-tab.jpg)

33. On the task's *Configuration* tab, under *Networking*: network mode **awsvpc**, the task's own ENI, a **private IP** from `ecs-public-1a` (here `10.0.1.6`) and a **public IP**.

   ![Task networking – awsvpc, private IP, public IP](images/fargate-33-task-networking.jpg)

34. Open `http://<public-ip>` in your browser:

   ![whoami answers from the Fargate task](images/fargate-34-browser-whoami.jpg)

   - `Name: fargate` comes from the environment variable `WHOAMI_NAME`.
   - `Hostname` is the **task ID**: there's no EC2 host behind it.
   - `IP: 10.0.1.6` is the task's **own VPC address**. In Lab 1, the container had a `172.17.0.x` address on the Docker bridge of the instance.
   - `RemoteAddr` is **your** IP: nothing sits between you and the task.

   > The screenshot shows only the first lines of the page. The rest are your browser's request headers.

35. Open the cluster's **Infrastructure** tab: the capacity providers are **Fargate** and **Fargate Spot**, and there are **0 container instances**.

   ![Infrastructure – Fargate capacity providers, 0 container instances](images/fargate-35-infrastructure-no-instances.jpg)

36. In **EC2 → Network interfaces**, filter by `fargate-tasks-sg`: one interface per task, one in each Availability Zone. The description is an `arn:aws:ecs:…:attachment/…` ARN, which shows that **ECS** created them.

   ![Network interfaces – one ENI per task, created by ECS](images/fargate-36-task-enis.jpg)

### Part F: Scale without servers

37. Open the service and choose **Update service**.

   ![whoami-fargate-svc – Update service](images/fargate-37-update-service.jpg)

38. **Desired tasks: 4**.

   ![Update service – desired tasks 4](images/fargate-38-desired-4.jpg)

39. Scroll down and choose **Update**.

   ![Update service – Update](images/fargate-39-update-button.jpg)

40. About **35 seconds** later, **4 tasks** are running, two in each subnet. You didn't add an instance, an Auto Scaling Group or any capacity.

   ![4 running tasks, 2 per Availability Zone](images/fargate-40-four-tasks.jpg)

41. Select one task, then choose **Stop → Stop selected**.

   ![Stop – Stop selected](images/fargate-41-stop-selected.jpg)

42. Confirm with **Stop**. The dialog reminds you that tasks started by a service are normally stopped by updating the service. Here you stop one on purpose, to test self-healing.

   ![Stop task – confirm](images/fargate-42-stop-confirm.jpg)

43. About 20 seconds later, the stopped task is **Stopped**, and the service has already started a **replacement**, so 4 tasks are running again.

   ![The stopped task and its replacement](images/fargate-43-task-replaced.jpg)

   The service's *Events* tab shows:

   ```
   (service whoami-fargate-svc) has started 1 tasks: (task b0ba90a292034e9f9ef9e982854f6ddb).
   (service whoami-fargate-svc) has reached a steady state.
   ```

   Then choose **Update service** again and set the desired tasks back to **2**.

### Part G: Clean up

Keep **`ecs-vpc`** and **`ecsTaskExecutionRole`**: the next labs use them. Delete everything else.

44. In the service, choose **Delete service**.

   ![Delete service](images/fargate-44-delete-service.jpg)

45. Check **Force delete** (it scales the service to 0 first), type `delete` and choose **Delete**.

   ![Delete service – Force delete, confirm](images/fargate-45-delete-service-confirm.jpg)

46. In the cluster, choose **Actions → Delete cluster**.

   ![Cluster Actions – Delete cluster](images/fargate-46-delete-cluster.jpg)

47. Type `delete ecs-fargate` and choose **Delete**.

   ![Delete cluster – confirm](images/fargate-47-delete-cluster-confirm.jpg)

48. **Task definitions → `whoami-fargate`**: select the revision, then **Actions → Deregister**. After that, **Delete** is available for the inactive revision.

   ![Task definition – Actions – Deregister](images/fargate-48-deregister-task-definition.jpg)

49. **EC2 → Security Groups**: select `fargate-tasks-sg`, then **Actions → Delete security groups**.

   ![Security Groups – Delete security groups](images/fargate-49-delete-security-group.jpg)

50. Choose **Delete**. If the group is still *in use*, wait a minute until the tasks' network interfaces are released.

   ![Delete security group – confirm](images/fargate-50-delete-security-group-confirm.jpg)

---

## Solution 2: AWS CLI

Run the steps in order, in one terminal: later steps use the variables from earlier ones.

### Part A: Find the network and create the cluster

Look up `ecs-vpc` and its two subnets by name. The service needs the subnet IDs as a comma-separated list.

```bash
export AWS_PAGER="" AWS_REGION=us-east-1
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=ecs-vpc --query 'Vpcs[0].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Subnets[].SubnetId' --output text | tr '\t' ',')
echo $VPC_ID $SUBNETS
```

A Fargate-only cluster needs nothing but a name:

```bash
aws ecs create-cluster --cluster-name ecs-fargate --query 'cluster.[clusterName,status]' --output text
```

```
ecs-fargate	ACTIVE
```

### Part B: The execution role and the task definition

ECS needs a **task execution role** to pull the image and send logs. Create it once per account. Skip this block if `ecsTaskExecutionRole` already exists, for example because the Console created it.

```bash
cat > ecs-tasks-trust.json <<'JSON'
{ "Version": "2012-10-17", "Statement": [{ "Effect": "Allow", "Principal": { "Service": "ecs-tasks.amazonaws.com" }, "Action": "sts:AssumeRole" }] }
JSON
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://ecs-tasks-trust.json
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

Write the task definition. On Fargate, `cpu` and `memory` are set for the whole task, and `networkMode` must be `awsvpc`:

```bash
EXEC_ROLE_ARN=$(aws iam get-role --role-name ecsTaskExecutionRole --query Role.Arn --output text)
cat > td-fargate.json <<JSON
{
  "family": "whoami-fargate",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "runtimePlatform": { "operatingSystemFamily": "LINUX", "cpuArchitecture": "X86_64" },
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "$EXEC_ROLE_ARN",
  "containerDefinitions": [{
    "name": "whoami",
    "image": "traefik/whoami",
    "essential": true,
    "portMappings": [{ "containerPort": 80, "protocol": "tcp" }],
    "environment": [{ "name": "WHOAMI_NAME", "value": "fargate" }]
  }]
}
JSON
aws ecs register-task-definition --cli-input-json file://td-fargate.json \
  --query 'taskDefinition.[family,revision,networkMode,cpu,memory]' --output text
```

```
whoami-fargate	3	awsvpc	256	512
```

The second field is the **revision**. It's `1` the first time you register a family, and here it's `3` because the family had earlier revisions.

### Part C: The security group

Allow HTTP only from your own public IP:

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
TASK_SG=$(aws ec2 create-security-group --group-name fargate-tasks-sg \
  --description "Fargate tasks - HTTP from my IP" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $TASK_SG --protocol tcp --port 80 --cidr $MY_IP/32 \
  --query 'SecurityGroupRules[0].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output text
```

```
tcp	80	80	203.0.113.10/32
```

### Part D: The service

`--network-configuration` is where Fargate differs from Lab 1: you choose the subnets, the security group, and whether each task gets a public IP.

```bash
aws ecs create-service --cluster ecs-fargate --service-name whoami-fargate-svc \
  --task-definition whoami-fargate --desired-count 2 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$TASK_SG],assignPublicIp=ENABLED}" \
  --query 'service.[serviceName,status,launchType,desiredCount]' --output text
aws ecs wait services-stable --cluster ecs-fargate --services whoami-fargate-svc
```

```
whoami-fargate-svc	ACTIVE	FARGATE	2
```

The `wait` returned after **82 seconds**.

### Part E: Test and explore

Each task has its own network interface (ENI). Find each task's ENI, then its private and public IPs:

```bash
for TASK in $(aws ecs list-tasks --cluster ecs-fargate --service-name whoami-fargate-svc --query 'taskArns[]' --output text); do
  ENI=$(aws ecs describe-tasks --cluster ecs-fargate --tasks $TASK \
    --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)
  aws ec2 describe-network-interfaces --network-interface-ids $ENI \
    --query 'NetworkInterfaces[0].[NetworkInterfaceId,AvailabilityZone,PrivateIpAddress,Association.PublicIp]' --output text
done | tee ips.txt
```

```
eni-0b0c2688…	us-east-1b	10.0.2.73	203.0.113.21
eni-0658b113…	us-east-1a	10.0.1.148	203.0.113.22
```

Call each task on its public IP:

```bash
for IP in $(awk '{print $4}' ips.txt); do
  curl -s -m 5 http://$IP/ | grep -E '^(Name|Hostname|IP: 10\.)' | paste -sd' ' -
done
```

```
Name: fargate Hostname: 2204c35e87ca4aa5b5df76a94d8954f6-3131618372 IP: 10.0.2.73
Name: fargate Hostname: 7d5a0ca8a7b746e69eadbce844da30f9-3131618372 IP: 10.0.1.148
```

There are no container instances, only running tasks:

```bash
aws ecs describe-clusters --clusters ecs-fargate \
  --query 'clusters[0].[registeredContainerInstancesCount,runningTasksCount]' --output text
```

```
0	2
```

ECS created one ENI per task. The description is an ECS *attachment*:

```bash
aws ec2 describe-network-interfaces --filters Name=group-id,Values=$TASK_SG \
  --query 'NetworkInterfaces[].[NetworkInterfaceId,PrivateIpAddress,Description]' --output text
```

```
eni-0658b113…	10.0.1.148	arn:aws:ecs:us-east-1:123456789012:attachment/a048c66d-…
eni-0b0c2688…	10.0.2.73	arn:aws:ecs:us-east-1:123456789012:attachment/fed66084-…
```

### Part F: Scale and self-healing

Scale to 4 tasks. There's no capacity to add first:

```bash
aws ecs update-service --cluster ecs-fargate --service whoami-fargate-svc --desired-count 4 \
  --query 'service.desiredCount' --output text
aws ecs wait services-stable --cluster ecs-fargate --services whoami-fargate-svc
aws ecs describe-services --cluster ecs-fargate --services whoami-fargate-svc \
  --query 'services[0].[desiredCount,runningCount]' --output text
```

```
4	4
```

All 4 were running after about **35 seconds**. Now stop one task and let the service replace it:

```bash
TASK=$(aws ecs list-tasks --cluster ecs-fargate --service-name whoami-fargate-svc --query 'taskArns[0]' --output text)
aws ecs stop-task --cluster ecs-fargate --task $TASK --reason "Lab test: self-healing" \
  --query 'task.[lastStatus,desiredStatus]' --output text
sleep 40
aws ecs describe-services --cluster ecs-fargate --services whoami-fargate-svc \
  --query 'services[0].events[:2].message' --output text
```

```
RUNNING	STOPPED
(service whoami-fargate-svc) has started 1 tasks: (task e264b42087cf4466b14194cd9f265717).
(service whoami-fargate-svc) has reached a steady state.
```

Set the service back to 2 tasks:

```bash
aws ecs update-service --cluster ecs-fargate --service whoami-fargate-svc --desired-count 2 \
  --query 'service.desiredCount' --output text
```

### Part G: Clean up

Delete the service first (`--force` scales it to 0), then the cluster:

```bash
aws ecs delete-service --cluster ecs-fargate --service whoami-fargate-svc --force --query 'service.status' --output text
aws ecs wait services-inactive --cluster ecs-fargate --services whoami-fargate-svc
aws ecs delete-cluster --cluster ecs-fargate --query 'cluster.status' --output text
```

Deregister the task definition, then delete it:

```bash
REV=$(aws ecs describe-task-definition --task-definition whoami-fargate --query 'taskDefinition.revision' --output text)
aws ecs deregister-task-definition --task-definition whoami-fargate:$REV --query 'taskDefinition.status' --output text
aws ecs delete-task-definitions --task-definitions whoami-fargate:$REV --query 'taskDefinitions[0].status' --output text
```

The security group can be deleted only after the tasks' ENIs are gone:

```bash
until [ "$(aws ec2 describe-network-interfaces --filters Name=group-id,Values=$TASK_SG \
          --query 'length(NetworkInterfaces)' --output text)" = "0" ]; do sleep 10; done
aws ec2 delete-security-group --group-id $TASK_SG
```

Keep `ecs-vpc` and `ecsTaskExecutionRole` for the next labs.

---

## Answers

- **A security group per task:** with `awsvpc`, each task gets its **own ENI**, and a security group is attached to an ENI. In Lab 1 (bridge mode), all the containers shared the instance's ENI, and therefore its security group.
- **The public IP:** the tasks run in **public** subnets with no NAT gateway. Without a public IP, a task can't reach Docker Hub to pull `traefik/whoami`, so it fails to start, and you couldn't reach it from your browser either. In a **private subnet**, use a **NAT gateway**, or **VPC endpoints** for ECR and S3 if the image is in ECR, and reach the tasks through a load balancer.
- **What you didn't have to do in Part F:** add instances, increase an Auto Scaling Group, or check whether there was enough CPU, memory or free host ports. You only changed the task count, and AWS found the capacity.
- **One stable address:** every task has its own public IP, and a replacement task gets a **new** one, as you saw in Part F. Users need one address that doesn't change and that spreads requests over all the healthy tasks: a **load balancer** in front of the service, with a DNS name.

---

[⬅ Lab 3](jb-lab-3.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 4 ➡](jb-lab-4.md)

---

## Solution 3: Terraform

> ⚠️ The Terraform code below still builds the **previous** version of this lab: the service behind an Application Load Balancer, in the default VPC. It will be updated to match the steps above.

[`terraform/jb-lab-3/main.tf`](terraform/jb-lab-3/main.tf) is **standalone**. It creates the ALB with its default 404, both security groups, the Fargate-only cluster, its own task execution role `ecs-task-execution-role`, the IP target group with the `/fargate*` rule, and the service with 2 tasks.

```bash
cd terraform/jb-lab-3
terraform init
terraform apply      # about 3 minutes; prints the /fargate URL
for i in 1 2 3; do curl -s $(terraform output -raw url) | grep -E '^(Name|Hostname)' | paste -sd' ' -; done
terraform destroy    # about 9 minutes: the target group's 300-second deregistration delay
```

The tested run: `apply` took 157 s, and the targets were healthy about 80 s later. The two Fargate tasks answer from their own private IPs:

```
Name: fargate Hostname: ip-172-31-84-154.ec2.internal
Name: fargate Hostname: ip-172-31-24-230.ec2.internal
Name: fargate Hostname: ip-172-31-84-154.ec2.internal
```

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
