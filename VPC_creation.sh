#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

echo "Creating VPC..."
vpc_create=$(aws ec2 create-vpc --instance-tenancy "default" --cidr-block "172.16.0.0/16" --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shopping}]')

if [ $? -eq 0 ]; then
    vpc_id=$(echo ${vpc_create} | jq | grep "VpcId" | cut -d '"' -f 4)
    echo "VPC created successfully with ID: ${vpc_id}"
else
    echo "Failed to create VPC. Exiting..."
    exit 1
fi

aws ec2 modify-vpc-attribute --enable-dns-hostnames '{"Value":true}' --vpc-id "${vpc_id}"

echo "Creating Internet Gateway..."
igw_create=$(aws ec2 create-internet-gateway --tag-specifications '{"ResourceType":"internet-gateway","Tags":[{"Key":"Name","Value":"Shopping-igw"}]}')

if [ $? -eq 0 ]; then
    InternetGatewayId=$(echo ${igw_create} | jq | grep "InternetGatewayId" | cut -d '"' -f 4)
    echo "Internet Gateway created with ID: ${InternetGatewayId}"
else
    echo "Failed to create Internet Gateway. Exiting..."
    exit 1
fi

aws ec2 attach-internet-gateway --vpc-id "${vpc_id}" --internet-gateway-id "${InternetGatewayId}"

echo "Creating subnets..."
public_subnet1=$(aws ec2 create-subnet --vpc-id "${vpc_id}" --cidr-block "172.16.0.0/18" --availability-zone-id "aps1-az1" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"public-subnet1"}]}')
public_subnet2=$(aws ec2 create-subnet --vpc-id "${vpc_id}" --cidr-block "172.16.64.0/18" --availability-zone-id "aps1-az3" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"public-subnet2"}]}')
private_subnet1=$(aws ec2 create-subnet --vpc-id "${vpc_id}" --cidr-block "172.16.128.0/18" --availability-zone-id "aps1-az2" --tag-specifications '{"ResourceType":"subnet","Tags":[{"Key":"Name","Value":"private-subnet1"}]}')

if [ $? -eq 0 ]; then
    echo "Subnets created successfully."
else
    echo "Failed to create subnets. Exiting..."
    exit 1
fi

pubsubnet1ID=$(echo ${public_subnet1} | jq . | grep "SubnetId" | cut -d '"' -f 4)
pubsubnet2ID=$(echo ${public_subnet2} | jq . | grep "SubnetId" | cut -d '"' -f 4)
prisubnet1ID=$(echo ${private_subnet1} | jq . | grep "SubnetId" | cut -d '"' -f 4)

echo "Public Subnet 1 ID: ${pubsubnet1ID}"
echo "Public Subnet 2 ID: ${pubsubnet2ID}"
echo "Private Subnet ID: ${prisubnet1ID}"

aws ec2 modify-subnet-attribute --subnet-id ${pubsubnet1ID} --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id ${pubsubnet2ID} --map-public-ip-on-launch

echo "Allocating Elastic IP..."
elastic_ip=$(aws ec2 allocate-address --domain vpc)
AllocationId=$(echo ${elastic_ip} | jq | grep "AllocationId" | cut -d '"' -f 4)

echo "Creating NAT Gateway..."
nat_gateway=$(aws ec2 create-nat-gateway --subnet-id "${pubsubnet2ID}" --allocation-id "${AllocationId}" --tag-specifications '{"ResourceType":"natgateway","Tags":[{"Key":"Name","Value":"shopping-nat"}]}')
NatGatewayId=$(echo ${nat_gateway} | jq | grep "NatGatewayId" | cut -d '"' -f 4)

echo "Creating Route Tables..."
private_route_table=$(aws ec2 create-route-table --vpc-id "${vpc_id}" --tag-specifications '{"ResourceType":"route-table","Tags":[{"Key":"Name","Value":"shopping-private"}]}')
public_route_table=$(aws ec2 create-route-table --vpc-id "${vpc_id}" --tag-specifications '{"ResourceType":"route-table","Tags":[{"Key":"Name","Value":"shopping-public"}]}')

private_route_tableId=$(echo ${private_route_table} | jq . | grep "RouteTableId" | cut -d '"' -f 4)
public_route_tableId=$(echo ${public_route_table} | jq . | grep "RouteTableId" | cut -d '"' -f 4)

echo "Associating Route Tables..."
aws ec2 create-route --route-table-id "${private_route_tableId}" --destination-cidr-block "0.0.0.0/0" --nat-gateway-id "${NatGatewayId}"
aws ec2 create-route --route-table-id "${public_route_tableId}" --destination-cidr-block "0.0.0.0/0" --gateway-id "${InternetGatewayId}"

aws ec2 associate-route-table --subnet-id "${prisubnet1ID}" --route-table-id "${private_route_tableId}"
aws ec2 associate-route-table --subnet-id "${pubsubnet1ID}" --route-table-id "${public_route_tableId}"
aws ec2 associate-route-table --subnet-id "${pubsubnet2ID}" --route-table-id "${public_route_tableId}"

echo "VPC setup completed successfully!"
