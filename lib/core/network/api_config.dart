//https://orectic-noctilucent-ronan.ngrok-free.dev


class ApiConfig {
  static const String origin =
      'https://orectic-noctilucent-ronan.ngrok-free.dev';

  static const String baseUrl = '$origin/api/v2';
  static const String socketUrl = origin;

  static const String checkPhoneExists = '$baseUrl/auth/checkPhoneExists';
  static const String checkEmailExists = '$baseUrl/auth/checkEmailExists';
  static const String login = '$baseUrl/auth/login';
  static const String verifyLoginOtp = '/auth/verify-login-otp';
  static const String resendLoginOtp = '/auth/resend-login-otp';
  static const String firstLoginChangePassword =
      '/auth/first-login/change-password';
  static const String register = '$baseUrl/auth/register';
  static const String verifyRegister = '$baseUrl/auth/verify-register';
  static const String logout = '$baseUrl/auth/logout';

  static const String totpSetup = '$baseUrl/auth/totp/setup';
  static const String totpRecover = '$baseUrl/auth/totp/recover';
  static const String totpEnable = '$baseUrl/auth/totp/enable';
  static const String totpDisable = '$baseUrl/auth/totp/disable';
  static const String refreshToken = '$baseUrl/auth/refresh-token';
  static const String getMe = '$baseUrl/auth/me';
  static const String sendOtp = '$baseUrl/otp/send-otp';
  static const String verifyOtp = '$baseUrl/otp/verify-otp';

  static const String getWalletBalance = '$baseUrl/wallet/balance';
  static const String checkTransfer = '$baseUrl/wallet/check-transfer';
  static const String checkPin = '$baseUrl/wallet/check-pin';
  static const String verifyPinChallenge =
      '$baseUrl/wallet/verify-pin-challenge';
  static const String resendPinChallenge =
      '$baseUrl/wallet/resend-pin-challenge';

  // POSTPAID WALLET (VÍ TRẢ SAU)
  static const String postpaidInfo = '$baseUrl/postpaid/info';
  static const String postpaidWallet = '$baseUrl/postpaid/wallet';
  static const String postpaidActivate = '$baseUrl/postpaid/activate';
  static const String postpaidFreeze = '$baseUrl/postpaid/freeze';
  static const String postpaidUnfreeze = '$baseUrl/postpaid/unfreeze';
  static const String postpaidClose = '$baseUrl/postpaid/close';
  static const String postpaidEntries = '$baseUrl/postpaid/entries';
  static const String postpaidRepay = '$baseUrl/postpaid/repay';

  static const String findUser = '$baseUrl/user/find-user';
  static const String checkContact = '$baseUrl/user/check-contact';
  static const String checkPinStatus = '$baseUrl/user/pin-status';
  static const String createPin = '$baseUrl/user/create-pin';
  static const String verifyPin = '$baseUrl/user/verify-pin';
  static const String changePin = '$baseUrl/user/change-pin';
  static const String verifyPassword = '$baseUrl/user/verify-password';
  static const String changePassword = '$baseUrl/user/change-password';
  static const String userLimits = '$baseUrl/user/limits';
  static const String resetUserLimit = '$baseUrl/user/limits/reset';
  static const String updateFcmToken = '$baseUrl/user/fcm-token';

  static const String transfer = '$baseUrl/transaction/transfer';
  static const String topup = '$baseUrl/transaction/topup';
  static const String withdraw = '$baseUrl/transaction/withdraw';
  static const String payment = '$baseUrl/transaction/qr-payment';
  static const String previewFee = '$baseUrl/transaction/preview-fee';
  static const String history = '$baseUrl/transaction/history';
  static const String historySummary = '$baseUrl/transaction/summary';
  static const String historyExportEmail =
      '$baseUrl/transaction/export-email';

  static const String createStaticQRToken = '$baseUrl/payment/qr/static';
  static const String getUserInfoByStaticQR =
      '$baseUrl/payment/qr/static/resolve';

  static const String createDynamicQRToken = '$baseUrl/payment/qr/dynamic';
  static const String getDynamicQRToken = '$baseUrl/payment/qr/dynamic/resolve';

  static const String getBankLinkStatus = '$baseUrl/bank/status';
  static const String linkBankAccount = '$baseUrl/bank/link';
  static const String enableBankShowBalance = '$baseUrl/bank/show-balance';
  static const String hideBankBalance = '$baseUrl/bank/hide-balance';
  static const String unlinkBankAccount = '$baseUrl/bank/unlink';

  static const String forgotRequest = '$baseUrl/user/forgot/request';
  static const String forgotResendOtp = '$baseUrl/user/forgot/resend-otp';
  static const String forgotVerifyOtp = '$baseUrl/user/forgot/verify-otp';
  static const String forgotKyc = '$baseUrl/user/forgot/kyc';
  static const String resetPassword = '$baseUrl/user/reset-password';
  static const String resetPin = '$baseUrl/user/reset-pin';

  static const String checkUserKYC = '$baseUrl/kyc/check';
  static const String verifyKYC = '$baseUrl/kyc/verify';
  static const String updateKYC = '$baseUrl/kyc/update';
}