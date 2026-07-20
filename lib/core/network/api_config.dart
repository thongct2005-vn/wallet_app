//https://my-ewallet-api.onrender.com/api/v2
//https://orectic-noctilucent-ronan.ngrok-free.dev

class ApiConfig {

static const String baseUrl = 'https://orectic-noctilucent-ronan.ngrok-free.dev/api/v2';
static const String checkPhoneExists = '$baseUrl/auth/checkPhoneExists';
static const String login = '$baseUrl/auth/login';
static const String refreshToken = '$baseUrl/auth/refresh';
static const String getMe = '$baseUrl/auth/me';
}
