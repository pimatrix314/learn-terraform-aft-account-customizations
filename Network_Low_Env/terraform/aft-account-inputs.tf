module "aft_accounts_info" {
  providers                    = { aws = aws.aft_management_account_admin }
  source                       = "../../modules/ssm_parameter_by_path/"
  ssm_parameter_path           = local.ssm_parameter_path
  ssm_parameter_path_recursive = true
}
 
module "aft_account_list" {
  providers                    = { aws = aws.aft_management_account_admin }
  source                       = "../../modules/ssm_parameter_by_path/"
  ssm_parameter_path           = local.ssm_parameter_path_account_list
  ssm_parameter_path_recursive = true
}
 
data "aws_ssm_parameter" "master_org_id" {
  provider = aws.aft_management_account_admin
  name     = local.ssm_parameter_path_org_id
}
