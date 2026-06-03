package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestS3ApplyDestroy tests full apply/destroy cycle against kumo emulator.
// Requires kumo running on localhost:4566.
// Run with: KUMO=1 go test -v -run TestS3ApplyDestroy -timeout 5m
func TestS3ApplyDestroy(t *testing.T) {
	if os.Getenv("KUMO") == "" {
		t.Skip("Skipping apply test: set KUMO=1 and start kumo on :4566")
	}
	t.Parallel()

	opts := &terraform.Options{
		TerraformDir:    "./fixtures/s3",
		TerraformBinary: "tofu",
		NoColor:         true,
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	bucketName := terraform.Output(t, opts, "bucket_name")
	assert.Equal(t, "kumo-test-assets", bucketName)
}
