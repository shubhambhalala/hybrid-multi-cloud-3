#To declare provider and region
provider "aws" {
	region	= "ap-south-1"
}
#To create VPC
resource "aws_vpc" "wpmysqlvpc" {
	cidr_block		= "192.168.0.0/16"
	enable_dns_hostnames	= true
	instance_tenancy	= "default"
	tags = {
		Name = "wpvpc"
	}
}
#To create two subnet one for wordpress other for mysql
resource "aws_subnet" "wp" {
	vpc_id	   		= "${aws_vpc.wpmysqlvpc.id}"
	cidr_block		= "192.168.1.0/24"
	availability_zone	= "ap-south-1a"
	tags = {
		Name = "wpsubnet"
	}
}
resource "aws_subnet" "mysql" {
	vpc_id	   		= "${aws_vpc.wpmysqlvpc.id}"
	cidr_block		= "192.168.0.0/24"
	availability_zone	= "ap-south-1b"
	tags = {
		Name = "mysqlsubnet"
	}
}
#To create public facing gateway
resource "aws_internet_gateway" "igw" {
	vpc_id		= "${aws_vpc.wpmysqlvpc.id}"
	tags = {
		Name = "internetgw"
	}
}
#To create routing table for igw 
resource "aws_route_table" "rtigw" {
	vpc_id		= "${aws_vpc.wpmysqlvpc.id}"
	route {
		cidr_block	= "0.0.0.0/0"
		gateway_id	= "${aws_internet_gateway.igw.id}"
	}
	tags = {
		name = "routetableigw"
	}
}
#To associate it with wp subnet
resource "aws_route_table_association" "assowp" {
	subnet_id = "${aws_subnet.wp.id}"
	route_table_id	= "${aws_route_table.rtigw.id}"
}
#To create security group for wordpress
resource "aws_security_group" "wordpress" {
  	name        = "wp-sg"
  	description = "allow ssh and http traffic"
	vpc_id 	    = "${aws_vpc.wpmysqlvpc.id}"
  	ingress {
    		from_port   = 22
    		to_port     = 22
    		protocol    = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  	}


  	ingress {
    		from_port   = 80
    		to_port     = 80
    		protocol    = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  	}

  	egress {
    		from_port       = 0
    		to_port         = 0
    		protocol        = "-1"
    		cidr_blocks     = ["0.0.0.0/0"]
  	}
	tags = {
		Name = "wordpress-sg"
	}
}
#To create security group for mysql
resource "aws_security_group" "mysql" {
  	name        = "mysql-sg"
  	description = "allow connectivity"
	vpc_id 	    = "${aws_vpc.wpmysqlvpc.id}"
  	ingress {
    		from_port   = 3306
    		to_port     = 3306
    		protocol    = "tcp"
    		security_groups = [aws_security_group.wordpress.id]
  	}


  	egress {
    		from_port       = 0
    		to_port         = 0
    		protocol        = "-1"
    		cidr_blocks     = ["0.0.0.0/0"]
  	}
	tags = {
		Name = "mysql-sg"
	}
} 
#To launch instance with wordpress and mysql
resource "aws_instance" "wordpress" {
	ami				= "ami-000cbce3e1b899ebd"
	instance_type			= "t2.micro"
	associate_public_ip_address	= true
	subnet_id			= "${aws_subnet.wp.id}"
	vpc_security_group_ids		= [aws_security_group.wordpress.id]
	key_name			= "anotherkey"
	tags = {
		Name = "wordpress"
	}
}

resource "aws_instance" "mysql" {
	ami				= "ami-0019ac6129392a0f2"
	instance_type			= "t2.micro"
	vpc_security_group_ids		= [aws_security_group.mysql.id]
	subnet_id			= "${aws_subnet.mysql.id}"
	key_name			= "anotherkey"
	tags = {
		Name = "mysql"
	}
}
output "wordpress_dns" {
  	value = aws_instance.wordpress.public_dns
}