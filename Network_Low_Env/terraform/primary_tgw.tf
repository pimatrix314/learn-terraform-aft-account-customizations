module "transit_gateway" {
   source  = "terraform-aws-modules/transit-gateway/aws"
   version = "2.8.0"
   
   name    = local.tgw_name
   description = "Primary TGW"
   
   create_tgw                              = true
   amazon_side_asn                         = local.tgw_aws_asn
   enable_default_route_table_association  = false
   enable_default_route_table_propagation  = false
   enable_auto_accept_shared_attachments   = true
   enable_vpn_ecmp_support                 = false
   ram_allow_external_principals           = true
   ram_principals                          = ["471112710624"]
   ram_name                                = "ram_network_tgw_mum_01"
   
   tags = merge(
     local.common-tags
   )
}


resource "aws_ec2_transit_gateway_vpc_attachment" "network_vpc" {
   subnet_ids                                = aws_subnet.private_subnet[*].id
   transit_gateway_id                        = module.transit_gateway.ec2_transit_gateway_id
   vpc_id                                    = aws_vpc.network_vpc.id
   appliance_mode_support                    = "enable"
   dns_support                               = "enable"
   ipv6_support                              = "disable"
   transit_gateway_default_route_table_association = "false"
   transit_gateway_default_route_table_propagation = "false"
   tags = merge(
     { "Name" : "tgw-network-tgwattach-mum-01" },
     local.common-tags
   )
}

 
 resource "aws_ec2_transit_gateway_route" "network_route" {
    destination_cidr_block      = local.primary_vpc_cidr
	transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.network_vpc.id
	transit_gateway_route_table_id = module.transit_gateway.ec2_transit_gateway_route_table_id
}

#Shared-Dev Routes
