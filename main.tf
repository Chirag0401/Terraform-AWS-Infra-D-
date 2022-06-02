# Access Key ID:
# AKIATS6GRTYHE46F6A6F
# Secret Access Key:
# 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
# ami-0851b76e8b1bce90b

provider "aws" {
  region  = "ap-south-1"
  access_key = "AKIATS6GRTYHE46F6A6F"
  secret_key = "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"
}


resource "aws_vpc" "Prod-VPC" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "VPC-D$"
    }
}

resource "aws_internet_gateway" "Prod-GW" {
    vpc_id = aws_vpc.Prod-VPC.id
    tags = {
        Name = "GW-D$"
    }
}

resource "aws_route_table" "Prod-rt" {
    vpc_id = aws_vpc.Prod-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.Prod-GW.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.Prod-GW.id
    }

    tags = {
        Name = "RT-D$"
    }  
} 

resource "aws_subnet" "Subnet-1" {
    vpc_id = aws_vpc.Prod-VPC.id
    cidr_block = "10.0.1.0/24" 

    tags = {
      Name = "Subnet-D$"
    }
}

resource "aws_route_table_association" "a-1" {
    subnet_id = aws_subnet.Subnet-1.id
    route_table_id = aws_route_table.Prod-rt.id
}

resource "aws_security_group" "Prod-SG" {
    name = "allow_web_traffic"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.Prod-VPC.id

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
    tags = {
        Name = "Allow-web"
    }
}

resource "aws_network_interface" "Prod-Interface" {
    subnet_id = aws_subnet.Subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [ aws_security_group.Prod-SG.id ]
}

resource "aws_eip" "prod-eip" {
    vpc = true
    network_interface = aws_network_interface.Prod-Interface.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.Prod-GW]
}

resource "aws_instance" "Prod-Web-Server" {
    ami = "ami-0851b76e8b1bce90b"
    instance_type = "t2.micro"
    key_name = "main-key-D$"
    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.Prod-Interface.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
      Name = "Ubuntu-D$"
    }
  
}

