/// Tên route của màn nhập OTP, dùng để quay lại khi chụp KYC thất bại
const String kForgotOtpRoute = 'forgot_otp';

enum ForgotType { password, pin }

extension ForgotTypeX on ForgotType {
  /// Giá trị gửi lên server
  String get apiValue => this == ForgotType.pin ? 'pin' : 'password';

  String get label => this == ForgotType.pin ? 'mã PIN' : 'mật khẩu';

  String get title =>
      this == ForgotType.pin ? 'Quên mã PIN' : 'Quên mật khẩu';
}

/// Thông tin đi xuyên suốt các màn KYC khi dùng cho luồng quên mật khẩu / PIN.
/// Màn KYC nhận null thì chạy như KYC bình thường.
class ForgotKycArgs {
  final ForgotType type;
  final String kycToken;
  final String phone;
  final bool hasKyc;

  const ForgotKycArgs({
    required this.type,
    required this.kycToken,
    required this.phone,
    required this.hasKyc,
  });
}