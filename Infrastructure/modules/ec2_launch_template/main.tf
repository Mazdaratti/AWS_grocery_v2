resource "aws_launch_template" "grocery" {
  name          = var.launch_template_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [var.security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # Embed the user data script directly
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install CloudWatch Agent
              sudo yum install -y amazon-cloudwatch-agent

              # Configure the agent
              cat <<EOC > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/lib/docker/containers/**/*-json.log",
                          "log_group_name": "/app/docker-logs",
                          "log_stream_name": "{instance_id}",
                          "timezone": "UTC"
                        }
                      ]
                    }
                  }
                },
                "metrics": {
                  "metrics_collected": {
                    "cpu": {
                      "measurement": [
                        "cpu_usage_idle",
                        "cpu_usage_user",
                        "cpu_usage_system"
                      ],
                      "resources": [
                        "*"
                      ],
                      "totalcpu": true
                    },
                    "disk": {
                      "measurement": [
                        "used_percent",
                        "inodes_free"
                      ],
                      "resources": [
                        "/"
                      ]
                    },
                    "mem": {
                      "measurement": [
                        "mem_used_percent"
                      ]
                    },
                    "net": {
                      "measurement": [
                        "bytes_sent",
                        "bytes_recv"
                      ]
                    }
                  }
                }
              }
              EOC

              # Start the CloudWatch Agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF
  )
}