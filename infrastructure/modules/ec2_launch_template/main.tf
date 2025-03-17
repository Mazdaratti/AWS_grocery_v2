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
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    region             = var.region
    ecr_repository_url = var.ecr_repository_url
    image_tag          = var.image_tag
    ecr_domain         = split("/", var.ecr_repository_url)[0]
  }))
}