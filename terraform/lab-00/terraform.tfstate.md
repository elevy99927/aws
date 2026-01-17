```json
{
  "version": 4,
  "terraform_version": "1.9.4",
  "serial": 7,
  "lineage": "111111-630c-0fe5-dfe3-11111111",
  "outputs": {
    "ip": {
      "value": "46.137.50.36",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 2,
          "attributes": {
            "ami": "ami-11111111",
            "arn": "arn:aws:ec2:eu-west-1:11111111:instance/i-11111111",
            "associate_public_ip_address": true,
            "availability_zone": "eu-west-1a",
            "capacity_reservation_specification": [
              {
                "capacity_reservation_preference": "open",
                "capacity_reservation_target": []
              }
            ],
            "cpu_options": [
              {
                "amd_sev_snp": "",
                "core_count": 1,
                "threads_per_core": 1
              }
            ],
            "credit_specification": [
              {
                "cpu_credits": "standard"
              }
            ],
            "disable_api_stop": false,
            "disable_api_termination": false,
            "ebs_block_device": [],
            "ebs_optimized": false,
            "enable_primary_ipv6": null,
            "enclave_options": [
              {
                "enabled": false
              }
            ],
            "ephemeral_block_device": [],
            "force_destroy": false,
            "get_password_data": false,
            "hibernation": false,
            "host_id": "",
            "host_resource_group_arn": null,
            "iam_instance_profile": "",
            "id": "i-11111111",
            "instance_initiated_shutdown_behavior": "stop",
            "instance_lifecycle": "",
            "instance_market_options": [],
            "instance_state": "running",
            "instance_type": "t2.micro",
            "ipv6_address_count": 0,
            "ipv6_addresses": [],
            "key_name": "",
            "launch_template": [],
            "maintenance_options": [
              {
                "auto_recovery": "default"
              }
            ],
            "metadata_options": [
              {
                "http_endpoint": "enabled",
                "http_protocol_ipv6": "disabled",
                "http_put_response_hop_limit": 2,
                "http_tokens": "required",
                "instance_metadata_tags": "disabled"
              }
            ],
            "monitoring": false,
            "network_interface": [],
            "outpost_arn": "",
            "password_data": "",
            "placement_group": "",
            "placement_group_id": "",
            "placement_partition_number": 0,
            "primary_network_interface": [
              {
                "delete_on_termination": true,
                "network_interface_id": "eni-11111111"
              }
            ],
            "primary_network_interface_id": "eni-11111111",
            "private_dns": "ip-172-31-35-169.eu-west-1.compute.internal",
            "private_dns_name_options": [
              {
                "enable_resource_name_dns_a_record": false,
                "enable_resource_name_dns_aaaa_record": false,
                "hostname_type": "ip-name"
              }
            ],
            "private_ip": "172.31.35.169",
            "public_dns": "ec2-46-137-50-36.eu-west-1.compute.amazonaws.com",
            "public_ip": "46.137.50.36",
            "region": "eu-west-1",
            "root_block_device": [
              {
                "delete_on_termination": true,
                "device_name": "/dev/xvda",
                "encrypted": true,
                "iops": 3000,
                "kms_key_id": "arn:aws:kms:eu-west-1:11111111:key/38345af4-020c-4517-a11e-38f78bb4c503",
                "tags": {},
                "tags_all": {},
                "throughput": 125,
                "volume_id": "vol-11111111",
                "volume_size": 8,
                "volume_type": "gp3"
              }
            ],
            "secondary_private_ips": [],
            "security_groups": [
              "default"
            ],
            "source_dest_check": true,
            "spot_instance_request_id": "",
            "subnet_id": "subnet-11111111",
            "tags": null,
            "tags_all": {},
            "tenancy": "default",
            "timeouts": null,
            "user_data": null,
            "user_data_base64": null,
            "user_data_replace_on_change": false,
            "volume_tags": null,
            "vpc_security_group_ids": [
              "sg-11111111"
            ]
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJwMDAsMCwicmVhZCI6OTAwMDAwMDAwMDAwLCJ1cGRhdGUiOjYwMDAwMDAwMDAwMH0sInNjaGVtYV92ZXJzaW9uIjoiMiJ9"
        }
      ]
    }
  ],
  "check_results": null
}
```
