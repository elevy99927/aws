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

  # The same steps as the video, as scripts: build the rootfs, boot the guest, install Docker, save the base image,
  # then check.sh boots a copy of the base and runs the checks. Progress: ~/fc/logs on the host.
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    common         = file("${path.module}/scripts/common.sh")
    build_rootfs   = file("${path.module}/scripts/build-rootfs.sh")
    boot_guest     = file("${path.module}/scripts/boot-guest.sh")
    install_docker = file("${path.module}/scripts/install-docker.sh")
    save_base      = file("${path.module}/scripts/save-base.sh")
    check          = file("${path.module}/scripts/check.sh")
  })
  user_data_replace_on_change = true

  tags = { Name = "fc-agents-host" }
}
