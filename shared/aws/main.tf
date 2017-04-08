###################################################################################
########### Find AWS Resources to use later #######################################
###################################################################################

# Find default vpc
data "aws_vpc" "default" {
  default = true
}

# Find default subnets in var.aws_availabilty_zones
data "aws_subnet" "default" {
  count = "${length(var.availability_zones)}"
  availability_zone = "${element(var.availability_zones,count.index)}"
  default_for_az = true
}

