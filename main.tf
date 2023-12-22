provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

resource "aws_instance" "example" {
  ami           = "ami-079db87dc4c10ac91" # Amazon Linux 2 AMI, replace with your desired AMI
  instance_type = "t2.micro"
  key_name = "keyfordemo"
  tags = {
    Name = "example-instance"
  }

  # Create a security group for SSH access
  vpc_security_group_ids = [aws_security_group.example.id]

  provisioner "local-exec" {
    command = <<-EOF
      echo "---
_all:
  hosts:
    example_instance:
      ansible_host: ${self.public_ip}
      ansible_user: ec2-user
      ansible_python_interpreter: /usr/bin/python3
      ansible_ssh_private_key_file: keyfordemo.pem
  children:
    example_instances:
      hosts:
        example_instance
  vars:
    instance_ip: ${self.public_ip}
" > inventory
    EOF
  }

  provisioner "local-exec" {
    # Pause for 30 seconds before executing the Ansible playbook
    command = "sleep 60"
  }

  provisioner "local-exec" {
    # Execute the Ansible playbook using the created inventory file
    command = "ansible-playbook -i inventory configure_instance.yml"
  }
}

# Create a security group allowing SSH from your IP
resource "aws_security_group" "example" {
  name        = "allow-ssh-from-your-ip"
  description = "Allow SSH from your IP"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your actual public IP
  }
  ingress {
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]

}
	egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
}
# Output the public IP address for Ansible
output "instance_ip" {
  value = aws_instance.example.public_ip
}

