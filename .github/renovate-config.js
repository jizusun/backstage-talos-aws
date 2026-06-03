module.exports = {
  onboarding: false,
  extends: ['config:best-practices'],
  requireConfig: 'optional',
  enabledManagers: ['mise', 'dockerfile', 'github-actions'],
  prHourlyLimit: 0,
  prConcurrentLimit: 0,
};
