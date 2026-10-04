variable environment {
    description = "Deployment environment"
    type = string
}


variable vpc_cidr {
    description = "CIDR block for the VPC"
    type = string
}

variable public_subnet_cidrs {
    description = "CIDR blocks for the public subnet"
    type = list(string)
    validation {
        condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
        error_message = "public_subnet_cidrs must have one entry per AZ"
    }
}

variable private_app_subnet_cidrs {
    description = "CIDR blocks for the private application subnet"
    type = list(string)
    validation {
        condition     = length(var.private_app_subnet_cidrs) == length(var.availability_zones)
        error_message = "private_app_subnet_cidrs must have one entry per AZ"
    }
}

variable private_db_subnet_cidrs {
    description = "CIDR blocks for the private database subnet"
    type = list(string)
    validation {
        condition     = length(var.private_db_subnet_cidrs) == length(var.availability_zones)
        error_message = "private_db_subnet_cidrs must have one entry per AZ"
    }
}

variable availability_zones {
    description = "The list of availability zones for the VPC"
    type = list(string)
}

variable tags {
    description = "Additional tags to apply to resources"
    type = map(string)
    default = {}
}

variable nat_gateway_count {
    description = "Number of NAT Gateways to create"
    type = number

    validation {
        condition = var.nat_gateway_count == floor(var.nat_gateway_count)
        error_message = "nat_gateway_count must be an integer"

    }
    
    validation {
        condition = var.nat_gateway_count > 0
        error_message = "nat_gateway_count must be atleast 1 number"
    }

    validation {
        condition = var.nat_gateway_count <= length(var.availability_zones)
        error_message = "nat_gateway_count cannot exceed the number of availability zones"
    }
}


