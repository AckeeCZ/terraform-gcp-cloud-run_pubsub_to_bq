variable "topic_name" {
  description = "Topic name to consume messages from"
}

variable "bigquery_table" {
  type        = string
  description = "`table_id` cloud function variable of the target table"
}


variable "region" {
  type = string
}

variable "project" {
  type = string
}