# Define the AWS provider
provider "aws" {
  # Use AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables
  region = "${var.aws_region}"
}

# define Route53 data source to retrieve the zone id
data "aws_route53_zone" "route53_zone" {
  name = "hashicorp-success.com."
}

# Create the EC2 instance to install pTFE
resource "aws_instance" "ptfe-demo" {
  ami           = "${var.amis}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.ssh_key_name}"

  # attach the security group
  vpc_security_group_ids = ["${aws_security_group.sec_group.id}"]

  # attach the subnet
  subnet_id = "${aws_subnet.subnet.id}"

  # allocate atleast 40GB space for the pre-requisites
  root_block_device {
    volume_size = "${var.ebs_volume_size}"
    volume_type = "${var.ebs_volume_type}"
  }

  # tags to name
  tags {
    Name  = "${var.resource_prefix_name}-demo"
    owner = "${var.owner}"
  }
}

# Create elastic IP and attach it to the EC2 instance
resource "aws_eip" "ptfe-demo" {
  instance = "${aws_instance.ptfe-demo.id}"
}

# Define the Route53 entry for the pTFE FQDN
resource "aws_route53_record" "route53_entry" {
  zone_id = "${data.aws_route53_zone.route53_zone.zone_id}"
  name    = "${var.resource_prefix_name}.hashicorp-success.com."
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.ptfe-demo.public_ip}"]
}
