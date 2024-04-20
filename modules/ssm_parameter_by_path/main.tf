terraform {
  required_providers {
    aws	= {
      source = "hashicorp/aws"
    }
  }
}

variable "ssm_parameter_path" {
  type        = string
  description = "path of ssm parameter to retrieve values from"
  default     = "/vv/aft/account_customization/output/"
}

variable "ssm_parameter_path_recursive" {
  type        = bool
  description = "path of ssm parameter to retrieve values from"
  default     = true
}

data "aws_ssm_parameters_by_path" "account_info" {
  path      = var.ssm_parameter_path
  recursive = var.ssm_parameter_path_recursive
}

# Return a map of {parameter_name, parameter_value}
output "param_name_values" {
  description = "map of parameter name and values"
  value       = zipmap(data.aws_ssm_parameters_by_path.account_info.names, data.aws_ssm_parameters_by_path.account_info.values)
}
