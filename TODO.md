# TODO

- [ ] **3.06 Containers – architecture diagram:** [`images/jb-ecs-ec2.jpg`](3.06-containers/images/jb-ecs-ec2.jpg) (source: `jb-ecs-ec2.drawio`) says *Default VPC (public subnets)*. The labs run in `ecs-vpc`, the VPC that students build in the [Networking lab](2.04-vpc-and-networking/lab-1.md).
- [ ] **3.05 Lambda – Labs 1–3 (`jb-lab-*.md`):** the 6 screenshots (`images/jb1-*`, `jb2-*`, `jb3-*`) and the Terraform code (`terraform/jb-lab-*`) still use the old `jb-` names. The lab text now uses `lab-1`, `lab-2-thumbnailer`, `lab-3-benchmark`.
- [ ] **3.05 Lambda – lab numbering:** the README's own LAB 1 and LAB 2 share their numbers with Labs 1–3 (`jb-lab-*.md`), and the chapter README doesn't link to Labs 1–3.
- [ ] **3.06 Containers – Fargate first:** the Fargate lab (`jb-lab-3.md`) is now standalone and will become Lab 1. Still to do: renumber the labs, rewrite the ALB lab for Fargate (IP targets), move the EC2 lab to the end, and update Labs 4–5, which still use the ALB from Lab 2 and expect `fargate-tasks-sg` to allow traffic from the ALB. `terraform/jb-lab-3` still builds the previous version (behind an ALB).
