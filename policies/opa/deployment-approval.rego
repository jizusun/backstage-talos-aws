package deployment.approval

import future.keywords.if
import future.keywords.in

default allow := false

# Dev, test, perf: no approval required
allow if {
  input.environment in ["dev", "test", "perf"]
}

# Staging and production: require approved status from authorized approver
allow if {
  input.environment in ["staging", "production"]
  input.approval_status == "approved"
  input.approver in data.authorized_approvers[input.environment]
}

# Violations for enforcement
violation[{"msg": msg, "severity": "critical"}] if {
  input.environment in ["staging", "production"]
  input.approval_status != "approved"
  msg := sprintf("Deployment to %s requires approval from authorized personnel", [input.environment])
}

violation[{"msg": msg, "severity": "critical"}] if {
  input.environment in ["staging", "production"]
  input.approval_status == "approved"
  not input.approver in data.authorized_approvers[input.environment]
  msg := sprintf("Approver %s is not authorized for %s deployments", [input.approver, input.environment])
}
