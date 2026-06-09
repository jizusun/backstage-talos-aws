package test

import (
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Layer 3: E2E tests (real AWS, needs credentials)
// Run with: AWS_PROFILE=dev go test -v -run TestE2E -timeout 30m

func TestE2EFullStack(t *testing.T) {
	if os.Getenv("E2E") == "" {
		t.Skip("Skipping E2E test: set E2E=1 and configure AWS credentials")
	}

	opts := &terraform.Options{
		TerraformDir:    "../",
		TerraformBinary: "tofu",
		NoColor:         true,
		VarFiles:        []string{"environments/dev.tfvars"},
		Vars: map[string]interface{}{
			"db_password": "e2e-test-password-123!",
		},
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	// Verify cluster is reachable
	lbDNS := terraform.Output(t, opts, "lb_dns_name")
	require.NotEmpty(t, lbDNS)

	// Verify Kubernetes API responds
	url := fmt.Sprintf("https://%s:6443/healthz", lbDNS)
	retry.DoWithRetry(t, "Waiting for K8s API", 10, 30*time.Second, func() (string, error) {
		resp, err := http.Get(url)
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()
		if resp.StatusCode != 200 {
			return "", fmt.Errorf("expected 200, got %d", resp.StatusCode)
		}
		return "OK", nil
	})

	// Verify DB endpoint exists
	dbEndpoint := terraform.Output(t, opts, "database_endpoint")
	assert.Contains(t, dbEndpoint, "backstage")
}
