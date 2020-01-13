output "writer_endpoint" {
  value = "${aws_rds_cluster.cluster.endpoint}"
  description = "The Write Endpoint of Aurora."
}
output "reader_endpoint" {
  value = "${aws_rds_cluster.cluster.reader_endpoint}"
  description = "The Read Endpoint of Aurora."
}