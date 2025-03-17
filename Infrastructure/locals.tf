locals {
  db_dump_s3_key = "${var.db_dump_prefix}${var.db_dump_filename}"
  lambda_layer_s3_key  = "${var.layer_prefix}${var.layer_filename}"
}