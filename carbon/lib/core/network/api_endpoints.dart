class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String sendOtp = '/api/v1/auth/otp/send';
  static const String verifyOtp = '/api/v1/auth/otp/verify';
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String refresh = '/api/v1/auth/refresh';
  static const String validate = '/api/v1/auth/validate';
  static const String logout = '/api/v1/auth/logout';

  // Workers
  static const String workerProfile = '/api/v1/workers/profile';
  static String workerByUserId(String userId) => '/api/v1/workers/$userId';
  static String workerStatusByUserId(String userId) =>
      '/api/v1/workers/status/$userId';

  // Risk
  static const String riskEvaluate = '/api/v1/risk/evaluate';
  static const String riskDrift = '/api/v1/risk/drift';
  static const String riskFeedback = '/api/v1/risk/feedback';
  static const String riskHealth = '/api/v1/risk/health';

  // Pricing
  static const String pricingCalculate = '/api/v1/pricing/calculate';
  static const String pricingRecalculate = '/api/v1/pricing/recalculate';

  // Policy
  static const String policyCreate = '/api/v1/policy/create';
  static String policyByUserId(String userId) => '/api/v1/policy/$userId';
  static const String policyValidate = '/api/v1/policy/validate';
  static String policyCancelByUserId(String userId) =>
      '/api/v1/policy/cancel/$userId';

  // Backward-compatible aliases.
  static const String policyOptIn = policyCreate;
  static String policyOptOut(String workerId) => policyCancelByUserId(workerId);

  // Claims
  static const String claimsAuto = '/api/v1/claims/auto';
  static String claimsByUserId(String userId) => '/api/v1/claims/$userId';
  static String claimsHistoryByUserId(String userId) =>
      '/api/v1/claims/history/$userId';

  // Fraud
  static const String fraudCheck = '/api/v1/fraud/check';
  static String fraudScoreByUserId(String userId) =>
      '/api/v1/fraud/score/$userId';

  // Payout
  static String payoutByUserId(String userId) => '/api/v1/payout/$userId';
  static const String payoutProcess = '/api/v1/payout/process';
  static const String payoutRetry = '/api/v1/payout/retry';

  // Ledger
  static String ledgerByUserId(String userId) => '/api/v1/ledger/$userId';
  static const String ledgerEntry = '/api/v1/ledger/entry';
  static const String ledgerAudit = '/api/v1/ledger/audit';

  // Trigger / Events
  static const String triggerActive = '/api/v1/trigger/active';
  static const String triggerMock = '/api/v1/trigger/mock';
  static const String triggerWeather = '/api/v1/trigger/weather';
  static const String triggerStop = '/api/v1/trigger/stop';

  // Notifications
  static String notificationsByUserId(String userId) =>
      '/api/v1/notify/$userId';
  static const String notifySend = '/api/v1/notify/send';
  static const String notifyRetry = '/api/v1/notify/retry';

  // Analytics
  static const String analyticsDashboard = '/api/v1/analytics/dashboard';
  static String analyticsTimeseries({int days = 7}) =>
      '/api/v1/analytics/timeseries?days=$days';
  static const String analyticsZones = '/api/v1/analytics/zones';

  // Pool
  static const String poolStatus = '/api/v1/pool/status';
  static String poolLedgerByUserId(String userId) =>
      '/api/v1/pool/ledger/$userId';

  // General
  static const String health = '/';
}
