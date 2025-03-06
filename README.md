# Amazon Virtual Private Cloud (VPC) Setup using AWS CLI

## Introduction
Amazon Virtual Private Cloud (VPC) is a service that allows you to launch AWS resources in a logically isolated virtual network. With Amazon VPC, you have full control over your virtual networking environment, including selecting your own IP address range, creating subnets, and configuring route tables and network gateways. This enables secure and scalable cloud infrastructure tailored to your application's needs.

Using below commands we can set up a VPC using AWS CLI, including creating subnets, configuring internet and NAT gateways, and setting up route tables.

### Creating a VPC
```sh
aws ec2 create-vpc --instance-tenancy "default" --cidr-block "172.16.0.0/16" --tag-specifications '{"ResourceType":"vpc","Tags":[{"Key":"Name","Value":"Shopping"}]}' 
```
### Enable DNS Hostnames
```sh
aws ec2 modify-vpc-attribute --enable-dns-hostnames '{"Value":true}' --vpc-id "vpc-0d9326e8d536ea9e1" 
```
### Internet Gateway Creation
```sh
aws ec2 create-internet-gateway --tag-specifications '{"ResourceType":"internet-gateway","Tags":[{"Key":"Name","Value":"Shopping-igw"}]}'  
```
### Attach Internet Gateway to VPC
```sh
aws ec2 attach-internet-gateway --vpc-id "vpc-0d9326e8d536ea9e1" --internet-gateway-id "igw-0303d6e9933e0f81e"  
```
