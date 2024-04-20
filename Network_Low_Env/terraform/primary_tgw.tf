module "transit gateway" {
   source  = "terraform-aws-modules/transit-gateway/aws"
   version = "2.8.0"
   
   name    = local.tgw_name
   descrption = "Primary TGW"
   
   create_tgw                     = true
   amazon_side_asn                = local.tgw_aws_asn
   enable_default_route_table_association  = false
   enable_default_route_table_propogation  = false
   enable_auto_accept_shared_attachments   = true
   enable_vpn_ecmp_support                 = false
   ram_allow_external_principals           = false
   ram_principals                          = [local.root_ou_arn]
   ram_name                                = "ram_network_tgw_mum_01"
   
   tags = merge(
     local.common_tags
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
     local.common_tags
   )
}

resource "aws_route53_zone_association" "all_other_private_r53_zone_association" {
   count    = length(local.names_of_asso_service)
   vpc_id   = aws_vpc.network_vpc.id
   zone_id  = module.vpc_endpoint_info.param_name_values[join("", [local.vpc_endpoint_ssm_parameter_path, local.names_of_asso_service[count.index]])]
}

data "aws_ec2_transit_gateway_vpc_attachment" "inspection_egress_vpc" {
  filter {
     name = "state"
	 values = ["available"]
  }
  filter {
     name = "vpc-id"
	 values = [local.inspection_vpc.id]
  }
 }
 
 resource "aws_ec2_transit_gateway_route" "network route" {
    destination_cidr_block      = local.primary_vpc_cidr
	transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.network_vpc.id
	transit_gateway_route_table_id = module.transit_gateway_ec2_transit_gateway_route_table_id
}

#Shared-Dev Routes

resource "aws_ec2_transit_gateway_route" "shared_dev_route" {
    destination_cidr_block      = local.shared_dev_vpc_cidr
	transit_gateway_attachment_id = module.aft_accounts_info.param_name_values["${local.ssm_parameter_path}account-lz2-shared-dev/tgw_attachment_id"]
	transit_gateway_route_table_id = module.transit_gateway_ec2_transit_gateway_route_table_id
}
