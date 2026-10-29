//https://my-ewallet-api.onrender.com/api/v2
//https://orectic-noctilucent-ronan.ngrok-free.dev
//http://localhost:3000/api/v2

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
  static const String register = '$baseUrl/auth/register';
  static const String verifyRegister = '$baseUrl/auth/verify-register';
  static const String logout = '$baseUrl/auth/logout';

  // Google Authenticator (TOTP)
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

  static const String findUser = '$baseUrl/user/find-user';
  static const String checkContact = '$baseUrl/user/check-contact';
  static const String checkPinStatus = '$baseUrl/user/pin-status';
  static const String createPin = '$baseUrl/user/create-pin';
  static const String updateFcmToken = '$baseUrl/user/fcm-token';

  static const String transfer = '$baseUrl/transaction/transfer';
  static const String topup = '$baseUrl/transaction/topup';
  static const String withdraw = '$baseUrl/transaction/withdraw';
  static const String payment = '$baseUrl/transaction/qr-payment';
  static const String history = '$baseUrl/transaction/history';
  static const String historySummary = '$baseUrl/transaction/summary';

  static const String createStaticQRToken = '$baseUrl/payment/qr/static';
  static const String getUserInfoByStaticQR =
      '$baseUrl/payment/qr/static/resolve';

  static const String createDynamicQRToken = '$baseUrl/payment/qr/dynamic';
  static const String getDynamicQRToken = '$baseUrl/payment/qr/dynamic/resolve';

  static const String getBankLinkStatus = '$baseUrl/bank/status';
  static const String linkBankAccount = '$baseUrl/bank/link';

  static const String forgotRequest = '$baseUrl/user/forgot/request';
  static const String forgotResendOtp = '$baseUrl/user/forgot/resend-otp';
  static const String forgotVerifyOtp = '$baseUrl/user/forgot/verify-otp';
  static const String forgotKyc = '$baseUrl/user/forgot/kyc';
  static const String resetPassword = '$baseUrl/user/reset-password';
  static const String resetPin = '$baseUrl/user/reset-pin';

  static const String checkUserKYC = '$baseUrl/kyc/check';
  static const String verifyKYC = '$baseUrl/kyc/verify';
}
