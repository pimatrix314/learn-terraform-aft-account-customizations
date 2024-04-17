# Transit Gateway attachment and routing
data "aws_ec2_transit_gateway" "primary_network_tgw" {
  filter {
    name   = "owner-id"
    values = [local.network_account_id]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}
 
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_network" {
  subnet_ids                                      = aws_subnet.private_tgw_subnet[*].id
  transit_gateway_id                              = data.aws_ec2_transit_gateway.primary_network_tgw.id
  vpc_id                                          = aws_vpc.shared_dev_vpc.id
  appliance_mode_support                          = local.appliance_mode_support
  transit_gateway_default_route_table_association = local.tgw_default_rt_association
  transit_gateway_default_route_table_propagation = local.tgw_default_rt_propagation
  tags = merge(
    { "Name" = "${local.tgw_attachment_name}" },
    local.common_tags
  )
 
  depends_on = [
    aws_vpc.shared_dev_vpc
  ]
}