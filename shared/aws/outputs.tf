
output "availablility_zones" {
  value = ["${var.availability_zones}"]
}

output "region" {
  value = "${replace(element(var.availability_zones,0),"/[a-z]$/","")}"
}

output "subnet_ids" {
    value = ["${data.aws_subnet.default.*.id}"]
}

output "vpc_id" {
  value = "${data.aws_vpc.default.id}"
}

