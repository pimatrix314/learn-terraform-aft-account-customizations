resource "aws_vpc" "network_vpc" {
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
 
resource "aws_subnet" "private_subnet" {
  count             = length(local.private_subnet_list)
  vpc_id            = aws_vpc.network_vpc.id
  cidr_block        = local.private_subnet_list[count.index]
  availability_zone = local.availability_zones[count.index]
 
  tags = merge(
    {
      Name = try(
        local.private_subnet_name[count.index],
        format("${local.primary_vpc_name}-private-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table" "private_tgw_rt" {
  count  = length(local.private_subnet_list)
  vpc_id = aws_vpc.network_vpc.id
  tags = merge(
    {
      Name = try(
        local.private_subnet_rtb_name[count.index],
        format("${local.primary_vpc_name}-private-rt-%s", element(local.availability_zones, count.index))
      )
    },
    local.common_tags
  )
}
 
resource "aws_route_table_association" "private_tgw_rt_assoc" {
  count          = length(local.private_subnet_list)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_tgw_rt[count.index].id
}
 
resource "aws_route" "private_tgw_route" {
  count                  = length(local.private_subnet_list)
  route_table_id         = aws_route_table.private_tgw_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.transit_gateway.ec2_transit_gateway_id
 
  timeouts {
    create = "5m"
  }
}