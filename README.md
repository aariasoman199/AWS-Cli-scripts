# Amazon Virtual Private Cloud (VPC) Setup using AWS CLI

## Introduction
Amazon Virtual Private Cloud (VPC) is a service that allows you to launch AWS resources in a logically isolated virtual network. With Amazon VPC, you have full control over your virtual networking environment, including selecting your own IP address range, creating subnets, and configuring route tables and network gateways. This enables secure and scalable cloud infrastructure tailored to your application's needs.

Using below commands we can set up a VPC using AWS CLI, including creating subnets, configuring internet and NAT gateways, and setting up route tables.

### Creating a VPC
```sh
aws ec2 create-vpc --instance-tenancy "default" --cidr-block "172.16.0.0/16" --tag-specifications '{"ResourceType":"vpc","Tags":[{"Key":"Name","Value":"Shopping"}]}' 
```
### Describe VPC ID
```sh
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=Shopping" --query "Vpcs[*].VpcId" --output text
```
### Enable DNS Hostnames
```sh
aws ec2 modify-vpc-attribute --enable-dns-hostnames '{"Value":true}' --vpc-id "vpc-0d9326e8d536ea9e1" 
```
### Internet Gateway Creation
```sh
aws ec2 create-internet-gateway --tag-specifications '{"ResourceType":"internet-gateway","Tags":[{"Key":"Name","Value":"Shopping-igw"}]}'  
```
### Describe Internet Gateway ID
```sh
aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=Shopping-igw" --query "InternetGateways[*].InternetGatewayId" --output text
```
### Attach Internet Gateway to VPC
```sh
aws ec2 attach-internet-gateway --vpc-id "vpc-0d9326e8d536ea9e1" --internet-gateway-id "igw-0303d6e9933e0f81e"  
```
### Creating Subnets
```sh
aws ec2 create-subnet --vpc-id "vpc-0d9326e8d536ea9e1" --cidr-block "172.16.0.0/18" --availability-zone-id "aps1-az1" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"public-subnet1"}]}' 

aws ec2 create-subnet --vpc-id "vpc-0d9326e8d536ea9e1" --cidr-block "172.16.64.0/18" --availability-zone-id "aps1-az3" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"public-subnet2"}]}' 

aws ec2 create-subnet --vpc-id "vpc-0d9326e8d536ea9e1" --cidr-block "172.16.128.0/18" --availability-zone-id "aps1-az2" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"private-subnet1"}]}' "  
```
### Describe Subnet IDs
```sh
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0d9326e8d536ea9e1" --query "Subnets[*].{Name:Tags[?Key=='Name']|[0].Value, ID:SubnetId}" 
```
### Enable IPv4 on Public Subnets
```sh
aws ec2 modify-subnet-attribute --subnet-id "subnet-0970e30009665f52b" --map-public-ip-on-launch '{"Value":true}' 
aws ec2 modify-subnet-attribute --subnet-id "subnet-09e42f63e7e52de29" --map-public-ip-on-launch '{"Value":true}'  
```
### Allocate Elastic IP
```sh
aws ec2 allocate-address --domain vpc  
```
### Creating NAT Gateway
```sh
aws ec2 create-nat-gateway --subnet-id "subnet-09e42f63e7e52de29" --allocation-id "eipalloc-0fd7bdfbe327b3a9f" --tag-specifications '{"ResourceType":"natgateway","Tags":[{"Key":"Name","Value":"shopping-nat"}]}' 
```
### Describe NAT Gateway ID
```sh
aws ec2 describe-nat-gateways --filter "Name=subnet-id,Values=subnet-0970e30009665f52b" --query "NatGateways[*].NatGatewayId" --output text
```
### Create Private Route Table
```sh
aws ec2 create-route-table --vpc-id "vpc-0d9326e8d536ea9e1" --tag-specifications '{"ResourceType":"route-table","Tags":[{"Key":"Name","Value":"shopping-private"}]}' 
```
### Adding NAT Gateway as Route
```sh
aws ec2 create-route --route-table-id "rtb-00a650b1a5ac2ca23" --destination-cidr-block "0.0.0.0/0" --nat-gateway-id "nat-02f28ece425300a2f" 
```
### Create public route table
```sh
aws ec2 create-route-table --vpc-id "vpc-0d9326e8d536ea9e1" --tag-specifications '{"ResourceType":"route-table","Tags":[{"Key":"Name","Value":"shopping-public"}]}'  
```
### Describe Route Tables
```sh
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0a15b56e8bbd369cc" --query "RouteTables[*].{Name:Tags[?Key=='Name']|[0].Value, ID:RouteTableId}" 
```
### Adding Internet gateway to Public Route Table
```sh
aws ec2 create-route --route-table-id "rtb-063ebf39916bd6ae6" --destination-cidr-block "0.0.0.0/0" --gateway-id "igw-0303d6e9933e0f81e" 
```
### Associate Route Table
```sh
aws ec2 associate-route-table --subnet-id "subnet-0970e30009665f52b" --route-table-id "rtb-063ebf39916bd6ae6"
aws ec2 associate-route-table --subnet-id "subnet-09e42f63e7e52de29" --route-table-id "rtb-063ebf39916bd6ae6"
aws ec2 associate-route-table --subnet-id "subnet-0cf6f1065305ba39f" --route-table-id "rtb-00a650b1a5ac2ca23"
```
### Conclusion
This guide provides a step-by-step process to create a fully functional Amazon VPC using AWS CLI. By following these commands, you can set up a secure and scalable network infrastructure tailored to your application's needs.
