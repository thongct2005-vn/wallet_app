//https://my-ewallet-api.onrender.com/api/v2
//https://orectic-noctilucent-ronan.ngrok-free.dev
//http://localhost:3000/api/v2

class ApiConfig {

static const String baseUrl = 'https://orectic-noctilucent-ronan.ngrok-free.dev/api/v2';
static const String checkPhoneExists = '$baseUrl/auth/checkPhoneExists';
static const String login = '$baseUrl/auth/login';
static const String refreshToken = '$baseUrl/auth/refresh-token';
static const String getMe = '$baseUrl/auth/me';
static const String sendOtp = '$baseUrl/auth/send-otp';
static const String verifyOtp = '$baseUrl/auth/verify-otp';



static const String getWalletBalance = '$baseUrl/wallet/balance';
static const String checkTransfer = '$baseUrl/wallet/check-transfer';
static const String checkPin = '$baseUrl/wallet/check-pin';



static const String findUser = '$baseUrl/user/find-user';
static const String checkContact = '$baseUrl/user/check-contact';
static const String checkPinStatus = '$baseUrl/user/pin-status';
static const String createPin = '$baseUrl/user/create-pin';
}
