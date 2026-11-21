# One fixed command, four checked values passed as environment variables (the CLI path creates the same file).
resource "aws_ssm_document" "pr_job" {
  name            = "fc-run-pr-job"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("${path.module}/ssm/fc-run-pr-job.yaml")
}
