# Ubuntu Server 24.04 LTS, x86_64, the newest build from Canonical.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "host" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.INSTANCE_TYPE
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.host.id]
  key_name               = aws_key_pair.host.key_name
  iam_instance_profile   = aws_iam_instance_profile.host.name # Part 4: the host's role (iam-host.tf)

  # KVM inside the instance, so Firecracker can run microVMs.
  cpu_options {
    nested_virtualization = "enabled"
  }

  # Room for the Ubuntu tarball, two sparse 4 GB disks and Docker images.
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # IMDSv2 with a hop limit of 1: the instance metadata can't be reached from behind the guest's NAT.
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Part 2's scripts (the Ubuntu guest, Docker, the base image), then Part 3's: bake-agents.sh bakes the three
  # agents into the base image, and check-jobs.sh runs two jobs with run-job.sh. Progress: ~/fc/logs on the host.
  # Part 4 adds pr-job.sh, jobctl, pr-job.env (the bucket) and the AWS CLI. Part 5 changes host-net.sh, run-job.sh,
  # pr-job.sh and jobctl, and adds check-parallel.sh (run by hand). Changing user data replaces the host.
  # Gzipped: user data is limited to 16 KB, and with the Part 3 scripts it passed that; cloud-init unpacks it.
  user_data_base64 = base64gzip(templatefile("${path.module}/user-data.sh.tftpl", {
    common         = file("${path.module}/scripts/common.sh")
    build_rootfs   = file("${path.module}/scripts/build-rootfs.sh")
    boot_guest     = file("${path.module}/scripts/boot-guest.sh")
    install_docker = file("${path.module}/scripts/install-docker.sh")
    save_base      = file("${path.module}/scripts/save-base.sh")
    check          = file("${path.module}/scripts/check.sh")
    host_net       = file("${path.module}/scripts/host-net.sh")
    bake_agents    = file("${path.module}/scripts/bake-agents.sh")
    run_job        = file("${path.module}/scripts/run-job.sh")
    check_jobs     = file("${path.module}/scripts/check-jobs.sh")
    check_parallel = file("${path.module}/scripts/check-parallel.sh")
    compose        = file("${path.module}/scripts/agents/compose.yaml")
    course_rules   = file("${path.module}/scripts/agents/rules/course.yaml")
    pr_job         = file("${path.module}/scripts/pr-job.sh")
    jobctl         = file("${path.module}/scripts/jobctl")
    bucket         = aws_s3_bucket.results.bucket
    region         = var.AWS_REGION
  }))
  user_data_replace_on_change = true

  tags = { Name = "fc-agents-host" }
}
