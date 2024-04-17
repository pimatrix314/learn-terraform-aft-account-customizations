resource "aws_vpc" "shared_dev_vpc" {
  cidr_block = local.primary_vpc_cidr
 
  instance_tenancy                 = local.instance_tenancy
  enable_dns_hostnames             = local.enable_dns_hostnames
  enable_dns_support               = local.enable_dns_support
  assign_generated_ipv6_cidr_block = local.assign_generated_ipv6_cidr_block
 
  tags = merge(
    { "Name"    = "${local.primary_vpc_name}",
      "flowlog" = "enable"
    },
    local.common_tags
  )
}
 
# Public subnet setup
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.shared_dev_vpc.id
 
  tags = merge(
    { "Name" = "${local.primary_igw_name}" },
    local.common_tags
  )
}
 
 
resource "aws_subnet" "public_alb_subnet" {
  count             = length(local.public_alb_subnet_list)
  vpc_id            = aws_vpc.shared_dev_vpc.id
  cidr_block        = local.public_alb_subnet_list[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.public_alb_subnet_name[count.index],
        format("${local.primary_vpc_name}-public-alb-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
 
resource "aws_route_table" "public_alb_rt" {
  vpc_id = aws_vpc.shared_dev_vpc.id
  tags = merge(
    {
      Name = local.public_alb_rtb_name
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "public_alb_rt_assoc" {
  count          = length(local.public_alb_subnet_list)
  subnet_id      = element(aws_subnet.public_alb_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_alb_rt.id
}
 
resource "aws_route" "public_web_routes" {
  route_table_id         = aws_route_table.public_alb_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
 
  timeouts {
    create = "5m"
  }
}
 
#-----------------------------------------------------------------------------------------------------------------
# Private subnet setup for transit gateway attachment
resource "aws_subnet" "private_tgw_subnet" {
  count             = length(local.private_tgw_subnet_list)
  vpc_id            = aws_vpc.shared_dev_vpc.id
  cidr_block        = local.private_tgw_subnet_list[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.private_tgw_subnet_name[count.index],
        format("${local.primary_vpc_name}-private-tgw-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table" "private_tgw_rt" {
  vpc_id = aws_vpc.shared_dev_vpc.id
  tags = merge(
    {
      Name = local.private_tgw_rtb_name
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "private_tgw_rt_assoc" {
  count          = length(local.private_tgw_subnet_list)
  subnet_id      = element(aws_subnet.private_tgw_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_tgw_rt.id
}
 
resource "aws_route" "private_tgw_subnet_egress" {
  route_table_id         = aws_route_table.private_tgw_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.aws_ec2_transit_gateway.primary_network_tgw.id
 
  timeouts {
    create = "5m"
  }
}
#-----------------------------------------------------------------------------------------------------------------
 
# Private Subnet and route table association for WEB
resource "aws_subnet" "private_web_subnet" {
  count             = length(local.private_subnet_list_web)
  vpc_id            = aws_vpc.shared_dev_vpc.id
  cidr_block        = local.private_subnet_list_web[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.private_subnet_name_web[count.index],
        format("${local.primary_vpc_name}-private-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table" "private_web_rt" {
  vpc_id = aws_vpc.shared_dev_vpc.id
  tags = merge(
    {
      Name = local.private_subnet_rtb_name_web
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "private_web_rt_assoc" {
  count          = length(local.private_subnet_list_web)
  subnet_id      = element(aws_subnet.private_web_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_web_rt.id
 
  depends_on = [
    aws_route_table.private_web_rt
  ]
}
 
resource "aws_route" "private_web_route" {
  count                  = length(local.private_subnet_list_web)
  route_table_id         = aws_route_table.private_web_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = local.network_tgw_id
 
  timeouts {
    create = "5m"
  }
 
  depends_on = [
    aws_route_table.private_web_rt
  ]
}
 
#-----------------------------------------------------------------------------------------------------------------
 
# Private Subnet and route table association for APP
resource "aws_subnet" "private_app_subnet" {
  count             = length(local.private_subnet_list_app)
  vpc_id            = aws_vpc.shared_dev_vpc.id
  cidr_block        = local.private_subnet_list_app[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.private_subnet_name_app[count.index],
        format("${local.primary_vpc_name}-private-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table" "private_app_rt" {
  vpc_id = aws_vpc.shared_dev_vpc.id
  tags = merge(
    {
      Name = local.private_subnet_rtb_name_app
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "private_app_rt_assoc" {
  count          = length(local.private_subnet_list_app)
  subnet_id      = element(aws_subnet.private_app_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_app_rt.id
 
  depends_on = [
    aws_route_table.private_app_rt
  ]
}
 
resource "aws_route" "private_app_route" {
  count                  = length(local.private_subnet_list_app)
  route_table_id         = aws_route_table.private_app_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = local.network_tgw_id
 
  timeouts {
    create = "5m"
  }
 
  depends_on = [
    aws_route_table.private_app_rt
  ]
}
 
#-----------------------------------------------------------------------------------------------------------------
 
# Private Subnet and route table association for DB
resource "aws_subnet" "private_db_subnet" {
  count             = length(local.private_subnet_list_db)
  vpc_id            = aws_vpc.shared_dev_vpc.id
  cidr_block        = local.private_subnet_list_db[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.private_subnet_name_db[count.index],
        format("${local.primary_vpc_name}-private-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table" "private_db_rt" {
  vpc_id = aws_vpc.shared_dev_vpc.id
  tags = merge(
    {
      Name = local.private_subnet_rtb_name_db
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "private_db_rt_assoc" {
  count          = length(local.private_subnet_list_db)
  subnet_id      = element(aws_subnet.private_db_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_db_rt.id
 
  depends_on = [
    aws_route_table.private_db_rt
  ]
}
 
resource "aws_route" "private_db_route" {
  count                  = length(local.private_subnet_list_db)
  route_table_id         = aws_route_table.private_db_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = local.network_tgw_id
 
  timeouts {
    create = "5m"
  }
 
  depends_on = [
    aws_route_table.private_db_rt
  ]
}
 
#-----------------------------------------------------------------------------------------------------
# Share subnet with BEV_Dev Account
resource "aws_ram_resource_share" "shared_dev_subnet_sharing" {
  name                      = "ram_shared_dev_subnet_sharing_mum_01"
  allow_external_principals = false
  tags                      = local.common_tags
}
resource "aws_ram_resource_association" "shared_dev_subnet_assoc" {
  count              = length(local.shared_subnet_list)
  resource_arn       = local.shared_subnet_list[count.index]
  resource_share_arn = aws_ram_resource_share.shared_dev_subnet_sharing.arn
}
 
 
resource "aws_ram_principal_association" "shared_dev_principal" {
  principal          = "295136033060"
  resource_share_arn = aws_ram_resource_share.shared_dev_subnet_sharing.arn
}
 
#-----------------------------------------------------------------------------------------------------
# Share subnet with other sharing Account
 
resource "aws_ram_principal_association" "sharing_dev_principal" {
  count              = length(local.sharing_dev_account_list)
  principal          = local.sharing_dev_account_list[count.index]
  resource_share_arn = aws_ram_resource_share.shared_dev_subnet_sharing.arn
}
 
#--------------------------------------------------------------------------------------------
#Zone Association AREA
resource "aws_route53_zone_association" "shared_dev_private_r53_zone_association" {
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = ""
  # module.vpc_endpoint_info.param_name_values[join("", [local.vpc_endpoint_ssm_parameter_path, local.vpc_endpoint_list[count.index]])]
}
 
resource "aws_route53_zone_association" "ssm_private_r53_zone_association" {
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = ""
}
resource "aws_route53_zone_association" "ssmmessages_private_r53_zone_association" {
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = ""
}
 
resource "aws_route53_zone_association" "ec2messages_private_r53_zone_association" {
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = ""
}
 
resource "aws_route53_zone_association" "s3_private_r53_zone_association" {
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = ""
}
module "vpc_endpoint_info" {
  providers                    = { aws = aws.aft_management_account_admin }
  source                       = "../../modules/ssm_parameter_by_path/"
  ssm_parameter_path           = local.vpc_endpoint_ssm_parameter_path
  ssm_parameter_path_recursive = true
}
 
 
resource "aws_route53_zone_association" "all_other_private_r53_zone_association" {
  count   = length(local.names_of_asso_service)
  vpc_id  = aws_vpc.shared_dev_vpc.id
  zone_id = module.vpc_endpoint_info.param_name_values[join("", [local.vpc_endpoint_ssm_parameter_path, local.names_of_asso_service[count.index]])]
}