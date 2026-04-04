class ApiEndpoints {
  ApiEndpoints._();

  // Auth -> Identity Service (8005)
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';

  static const List<String> loginVariants = <String>[login];
  static const List<String> registerVariants = <String>[register];
  static const List<String> verifyOtpVariants = <String>[verifyOtp];
  static const List<String> resendOtpVariants = <String>[resendOtp];

  // Dashboard / overview -> Analytics (8011), Policy (8004), Claims (8009), Payout (8007)
  static const String dashboardSummary = '/analytics/summary';
  static const String dashboardTrends = '/analytics/trends';

  // Policy -> Policy Service (8004)
  static const String policyDetails = '/policy/details';
  static const String policyAccept = '/policy/accept';

  // Claims -> Claims Service (8009)
  static const String claimsList = '/claims/list';
  static const String claimsDetails = '/claims/details';

  // Payout -> Payout Service (8007)
  static const String payoutHistory = '/payout/history';
  static const String payoutStatus = '/payout/status';

  // Events -> Trigger Service (8008), AI Risk Service (8003)
  static const String eventsList = '/events/list';
  static const String eventsSeverity = '/events/severity';

  // Notifications -> Notification Service (8006)
  static const String notifications = '/notifications';
  static const String notificationsMarkRead = '/notifications/mark-read';

  // Settings -> Identity (8005), Notification (8006)
  static const String userPreferences = '/user/preferences';
  static const String updateSettings = '/user/update-settings';

  // Screen-level mapping to maintain endpoint ownership clarity.
  static const Map<String, List<String>> screenEndpointMap =
      <String, List<String>>{
        'login': <String>[login],
        'register': <String>[register, verifyOtp, resendOtp],
        'dashboard': <String>[dashboardSummary, dashboardTrends],
        'policy': <String>[policyDetails, policyAccept],
        'claims': <String>[claimsList, claimsDetails],
        'payout': <String>[payoutHistory, payoutStatus],
        'events': <String>[eventsList, eventsSeverity],
        'notifications': <String>[notifications, notificationsMarkRead],
        'settings': <String>[userPreferences, updateSettings],
      };
}
