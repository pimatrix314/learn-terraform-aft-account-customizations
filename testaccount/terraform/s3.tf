data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "testaccount13111993" {
  bucket = "aft-sandbox-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
}

