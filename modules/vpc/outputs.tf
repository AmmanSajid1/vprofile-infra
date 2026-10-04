output "vpc_id" {
    value = aws_vpc.vprofile_vpc.id
}

output "public_subnet_ids" {
    value = [for az in var.availability_zones : aws_subnet.vprofile_public_subnet[az].id]
}

output "private_app_subnet_ids" {
    value = [for az in var.availability_zones : aws_subnet.vprofile_private_app_subnet[az].id]
}

output "private_db_subnet_ids" {
    value = [for az in var.availability_zones : aws_subnet.vprofile_private_db_subnet[az].id]
}

