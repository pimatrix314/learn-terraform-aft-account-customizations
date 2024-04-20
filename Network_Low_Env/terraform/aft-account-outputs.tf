resource "aws_ssm_parameter" "outputs" {
  provider = aws.aft_management_account_admin
  for_each = local.export_output
  name     = "/vv/aft/account_customization/output/${local.account_name}/${each.key}"
  # Commenting below two lines as value cannot be of two different types
  # type     = contains(["public_hz_ns_records"], each.key) ? "StringList" : "String"
  # value    = contains(["public_hz_ns_records"], each.key) ? join(",",[for s in each.value : s]) : each.value
  type  = "String"
  value = each.value
}
 
resource "aws_ssm_parameter" "list_outputs" {
  provider = aws.aft_management_account_admin
  for_each = local.export_list_output
  name     = "/vv/aft/account_customization/output/${local.account_name}/${each.key}"
  type     = "StringList"
  value    = join(",", [for s in each.value : s])
}