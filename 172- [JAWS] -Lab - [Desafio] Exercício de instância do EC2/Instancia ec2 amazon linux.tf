provider "aws" {
  region = "us-west-2"  # Defina sua região AWS desejada
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.31.0.0/16"  # Substitua pelo bloco CIDR da sua VPC desejada
}

resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.31.16.0/20"  # Substitua pelo bloco CIDR da sua sub-rede desejada
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # AMI do Amazon Linux
  instance_type = "t3.small"
  subnet_id     = aws_subnet.my_subnet.id
  key_name      = "your_key_pair_name"  # Substitua pelo nome do seu par de chaves SSH

  tags = {
    Name = "WebServerInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              chmod 777 /var/www/html
              EOF

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8  # Tamanho do volume em GB
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/your_private_key.pem")  # Substitua pelo caminho para sua chave privada SSH
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'HTTPD Installed Successfully!'"
    ]
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
