package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Layer 1: Module validation tests (no AWS needed)

func TestVPCModuleValidation(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{
		TerraformDir:    "../modules/vpc",
		TerraformBinary: "tofu",
		NoColor:         true,
	}
	terraform.Init(t, opts)
	out, err := terraform.ValidateE(t, opts)
	require.NoError(t, err)
	assert.Contains(t, out, "Success")
}

func TestRDSModuleValidation(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{
		TerraformDir:    "../modules/rds",
		TerraformBinary: "tofu",
		NoColor:         true,
	}
	terraform.Init(t, opts)
	out, err := terraform.ValidateE(t, opts)
	require.NoError(t, err)
	assert.Contains(t, out, "Success")
}

func TestElastiCacheModuleValidation(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{
		TerraformDir:    "../modules/elasticache",
		TerraformBinary: "tofu",
		NoColor:         true,
	}
	terraform.Init(t, opts)
	out, err := terraform.ValidateE(t, opts)
	require.NoError(t, err)
	assert.Contains(t, out, "Success")
}

func TestS3ModuleValidation(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{
		TerraformDir:    "../modules/s3",
		TerraformBinary: "tofu",
		NoColor:         true,
	}
	terraform.Init(t, opts)
	out, err := terraform.ValidateE(t, opts)
	require.NoError(t, err)
	assert.Contains(t, out, "Success")
}

func TestECRModuleValidation(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{
		TerraformDir:    "../modules/ecr",
		TerraformBinary: "tofu",
		NoColor:         true,
	}
	terraform.Init(t, opts)
	out, err := terraform.ValidateE(t, opts)
	require.NoError(t, err)
	assert.Contains(t, out, "Success")
}
