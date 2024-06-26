locals {
  account_name      = "account-lz2-network"
  primary_vpc_name  = "vpc-network-mum-01"
  primary_region    = "ap-south-1"
  availability_zones = ["${local.primary_region}a", "${local.primary_region}b"]
  
  primary_vpc_cidr   = "10.1.0.0/16"
	
  
  private_subnet_list    = ["10.1.0.0/17", "10.1.128.0/17"]
  private_subnet_name    = ["snt-nw-tgwattach-mum-a01", "snt-nw-tgwattach-mum-b01"]
  private_subnet_routetable = ["rtb-nw-private-mum-a01", "rtb-nw-private-mum-b01"]
  
  instance_tenancy             = "default"
  enable_dns_support           = true
  enable_dns_hostnames         = true
  assign_generated_ipv6_cidr_block = false
  
  tgw_name       = "tgw-network-mum-01"
  tgw_aws_asn    = 65532
  root_ou_arn    = "arn:aws:organizations::211125643431:ou/o-5bsj7qdwcs/ou-8n5c-qm238uf9"
  
  common-tags = {
     requester-name         = "vikas dubey"
	 }
  ssm_parameter_path        = "/vv/aft/account_customization/output/"
  ssm_parameter_path_org_id = "/vv/static/master/org-id"
  ssm_parameter_path_account_list  = "/vv/aft/account_id/"
  
  #export outputs of type string
  export_output = {
         vpc_id           = aws_vpc.network_vpc.id
	 vpc_cidr         = aws_vpc.network_vpc.cidr_block
  }  
  #export outputs of type list
  export_list_output = {
  
  }
}
  
