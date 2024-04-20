# AFT Management account id
data "aws_caller_identity" "aft_management_account" {
  provider = aws.aft_management_account
}
 
data "aws_caller_identity" "current" {}
 
data "aws_region" "current" {}