locals {
    # Map: AZ name => index (for CIDR lookup)
    az_map = { for i, az in var.availability_zones : az => i }

    # Only first N AZs will get a NAT GW
    nat_map = { for k, v in local.az_map : k => v if v < var.nat_gateway_count }

    # Which NAT does each AZ's private app subnet route to?
    # If the AZ has its own NAT -> use it. Otherwise -> fall back to the first one
    app_nat_target = {
        for az, i in local.az_map :
        az => contains(keys(local.nat_map), az) ? az : keys(local.nat_map)[0]
    }
}

resource aws_vpc "vprofile_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-vpc" }
    )
}

resource aws_internet_gateway "vprofile_igw" {
    vpc_id = aws_vpc.vprofile_vpc.id
    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-igw" }
    )
}

# Public subnets
resource "aws_subnet" "vprofile_public_subnet" {
    for_each = local.az_map
    vpc_id = aws_vpc.vprofile_vpc.id
    cidr_block = var.public_subnet_cidrs[each.value]
    availability_zone = each.key
    map_public_ip_on_launch = true
    
    tags = merge(var.tags, { Name = "vprofile-${var.environment}-public-${each.key}"})
}

# Private application subnets
resource "aws_subnet" "vprofile_private_app_subnet" {
    for_each = local.az_map
    vpc_id = aws_vpc.vprofile_vpc.id
    cidr_block = var.private_app_subnet_cidrs[each.value]
    availability_zone = each.key
    
    tags = merge(var.tags, { Name = "vprofile-${var.environment}-private-app-${each.key}"})
}

# Private database subnets
resource "aws_subnet" "vprofile_private_db_subnet" {
    for_each = local.az_map
    vpc_id = aws_vpc.vprofile_vpc.id
    cidr_block = var.private_db_subnet_cidrs[each.value]
    availability_zone = each.key

    tags = merge(var.tags, { Name = "vprofile-${var.environment}-db-${each.key}"})
}


# NAT Gateways and Elastic IPs
resource aws_eip "vprofile_nat_eip" {
    for_each = local.nat_map
    domain = "vpc"
    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-nat-eip-${each.key}" }
    )
}

resource "aws_nat_gateway" "vprofile_nat_gateway" {
    for_each = local.nat_map
    allocation_id = aws_eip.vprofile_nat_eip[each.key].id
    subnet_id = aws_subnet.vprofile_public_subnet[each.key].id
    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-nat-gateway-${each.key}" }
    )

}

# Public route table and associations
resource "aws_route_table" "vprofile_public_rt" {
    vpc_id = aws_vpc.vprofile_vpc.id
    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-public-rt" }
    )
}

resource "aws_route" "vprofile_public_route" {
    route_table_id = aws_route_table.vprofile_public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vprofile_igw.id
}

resource "aws_route_table_association" "vprofile_public_rta" {
    for_each = local.az_map
    subnet_id = aws_subnet.vprofile_public_subnet[each.key].id
    route_table_id = aws_route_table.vprofile_public_rt.id
}

# Private application route table and associations
resource "aws_route_table" "vprofile_private_app_rt" {
    for_each = local.az_map
    vpc_id = aws_vpc.vprofile_vpc.id

    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-private-app-rt-${each.key}" }
    )
}

resource "aws_route" "vprofile_private_app_route" {
    for_each = local.az_map
    route_table_id = aws_route_table.vprofile_private_app_rt[each.key].id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vprofile_nat_gateway[local.app_nat_target[each.key]].id
}

resource "aws_route_table_association" "vprofile_private_app_rta" {
    for_each = local.az_map
    subnet_id = aws_subnet.vprofile_private_app_subnet[each.key].id
    route_table_id = aws_route_table.vprofile_private_app_rt[each.key].id
}

# Private database route table and associations
resource "aws_route_table" "vprofile_private_db_rt" {
    vpc_id = aws_vpc.vprofile_vpc.id

    tags = merge(
        var.tags,
        { Name = "vprofile-${var.environment}-private-db-rt"}
    )
}

resource "aws_route_table_association" "vprofile_private_db_rta" {
    for_each = local.az_map
    subnet_id = aws_subnet.vprofile_private_db_subnet[each.key].id
    route_table_id = aws_route_table.vprofile_private_db_rt.id
}