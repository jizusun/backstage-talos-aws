# Integration test: apply/destroy S3 module against kumo emulator
# Run: kumo & sleep 2 && tofu test -chdir=terraform/tests/setup

run "s3_bucket_created" {
  command = apply

  assert {
    condition     = output.bucket_id == "kumo-test-assets"
    error_message = "S3 bucket ID should be kumo-test-assets"
  }
}
