import 'dart:convert';
import 'dart:typed_data';
import 'package:app/src/auth/login/first_login_change_password_screen.dart';
import 'package:app/src/auth/login/login_phone_screen.dart';
import 'package:app/src/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) onFetch;

  _StubHttpClientAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => onFetch(options, requestStream, cancelFuture);

  @override
  void close({bool force = false}) {}
}

class _FakeAuthService extends AuthService {
  Future<Map<String, dynamic>> Function({
    required String changePasswordToken,
    required String newPassword,
    required String confirmPassword,
  })? onChangeFirstLoginPassword;

  int callCount = 0;
  String? lastToken;
  String? lastNewPassword;
  String? lastConfirmPassword;

  @override
  Future<Map<String, dynamic>> changeFirstLoginPassword({
    required String changePasswordToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    callCount++;
    lastToken = changePasswordToken;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmPassword;
    if (onChangeFirstLoginPassword != null) {
      return onChangeFirstLoginPassword!(
        changePasswordToken: changePasswordToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    }
    return {
      'is_success': true,
      'message':
          'Đổi mật khẩu thành công. Vui lòng đăng nhập lại bằng mật khẩu mới',
    };
  }
}

void main() {
  group('AuthService first-login flow', () {
    test(
      'verifyLoginOtp trả về must_change_password=true cùng change_password_token mà không cần token',
      () async {
        final service = AuthService();
        final originalAdapter = service.api.httpClientAdapter;
        addTearDown(() => service.api.httpClientAdapter = originalAdapter);

        RequestOptions? capturedOptions;
        service.api.httpClientAdapter = _StubHttpClientAdapter((
          options,
          _,
          _,
        ) async {
          capturedOptions = options;
          return ResponseBody.fromString(
            jsonEncode({
              'status': 'success',
              'message': 'Vui lòng đổi mật khẩu trong lần đăng nhập đầu tiên',
              'data': {
                'must_change_password': true,
                'change_password_token': 'change-tok-xyz',
                'user_info': {
                  'user_id': 'u-1',
                  'full_name': 'Nguyễn Văn Mới',
                  'phone': '0912345678',
                },
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final res = await service.verifyLoginOtp('otp-tok-123', '654321');

        expect(capturedOptions?.path, '/auth/verify-login-otp');
        expect(capturedOptions?.headers['x-otp-token'], 'otp-tok-123');
        expect(capturedOptions?.extra['skipAuth'], isTrue);
        expect(res['is_success'], isTrue);
        expect(res['must_change_password'], isTrue);
        expect(res['change_password_token'], 'change-tok-xyz');
        expect(res['user_id'], 'u-1');
        expect(res['phone'], '0912345678');
      },
    );

    test(
      'changeFirstLoginPassword gửi PATCH /auth/first-login/change-password kèm x-change-password-token và xử lý lỗi',
      () async {
        final service = AuthService();
        final originalAdapter = service.api.httpClientAdapter;
        addTearDown(() => service.api.httpClientAdapter = originalAdapter);

        RequestOptions? capturedOptions;
        var nextStatus = 200;
        var nextBody = <String, dynamic>{
          'status': 'success',
          'message': 'Đổi mật khẩu thành công',
          'data': {'must_change_password': false, 'require_relogin': true},
        };

        service.api.httpClientAdapter = _StubHttpClientAdapter((
          options,
          _,
          _,
        ) async {
          capturedOptions = options;
          return ResponseBody.fromString(
            jsonEncode(nextBody),
            nextStatus,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final ok = await service.changeFirstLoginPassword(
          changePasswordToken: 'first-login-jwt',
          newPassword: '246810',
          confirmPassword: '246810',
        );

        expect(capturedOptions?.method, 'PATCH');
        expect(capturedOptions?.path, '/auth/first-login/change-password');
        expect(
          capturedOptions?.headers['x-change-password-token'],
          'first-login-jwt',
        );
        expect(capturedOptions?.data, {
          'new_password': '246810',
          'confirm_password': '246810',
        });
        expect(ok['is_success'], isTrue);

        nextStatus = 400;
        nextBody = {
          'status': 'error',
          'message': 'Mật khẩu mới không được trùng mật khẩu tạm thời',
        };
        final err = await service.changeFirstLoginPassword(
          changePasswordToken: 'first-login-jwt',
          newPassword: '482910',
          confirmPassword: '482910',
        );
        expect(err['is_success'], isFalse);
        expect(err['status_code'], 400);
        expect(
          err['message'],
          'Mật khẩu mới không được trùng mật khẩu tạm thời',
        );
      },
    );
  });

  group('FirstLoginChangePasswordScreen', () {
    testWidgets(
      'Khóa PopScope(canPop: false), validate 6 chữ số & khớp mật khẩu, và hiển thị lỗi 400 tại chỗ',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeAuth = _FakeAuthService()
          ..onChangeFirstLoginPassword = ({
            required String changePasswordToken,
            required String newPassword,
            required String confirmPassword,
          }) async => {
            'is_success': false,
            'status_code': 400,
            'message': 'Mật khẩu mới không được trùng mật khẩu tạm thời',
          };

        await tester.pumpWidget(
          MaterialApp(
            home: FirstLoginChangePasswordScreen(
              changePasswordToken: 'change-tok-1',
              phoneNumber: '0912345678',
              authService: fakeAuth,
            ),
          ),
        );

        final popScope = tester.widget<PopScope>(
          find.descendant(
            of: find.byType(FirstLoginChangePasswordScreen),
            matching: find.byType(PopScope),
          ),
        );
        expect(popScope.canPop, isFalse);

        // Chưa nhập đủ 6 số
        await tester.tap(find.byKey(const Key('first_login_submit_button')));
        await tester.pump();
        expect(fakeAuth.callCount, 0);
        expect(
          find.text('Mật khẩu mới phải gồm đúng 6 chữ số'),
          findsOneWidget,
        );

        // Nhập mật khẩu xác nhận không khớp
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('first_login_new_password')),
            matching: find.byType(EditableText),
          ),
          '654321',
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('first_login_confirm_password')),
            matching: find.byType(EditableText),
          ),
          '111222',
        );
        await tester.tap(find.byKey(const Key('first_login_submit_button')));
        await tester.pump();
        expect(fakeAuth.callCount, 0);
        expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);

        // Nhập khớp 6 số nhưng server trả 400 -> giữ màn hình và báo lỗi
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('first_login_confirm_password')),
            matching: find.byType(EditableText),
          ),
          '654321',
        );
        await tester.tap(find.byKey(const Key('first_login_submit_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.callCount, 1);
        expect(find.byKey(const Key('first_login_error_text')), findsOneWidget);
        expect(
          find.text('Mật khẩu mới không được trùng mật khẩu tạm thời'),
          findsOneWidget,
        );
        expect(find.byType(FirstLoginChangePasswordScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Đổi mật khẩu thành công gọi API đúng tham số và pushAndRemoveUntil về LoginPhoneScreen',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeAuth = _FakeAuthService();

        await tester.pumpWidget(
          MaterialApp(
            home: FirstLoginChangePasswordScreen(
              changePasswordToken: 'change-tok-ok',
              phoneNumber: '0987654321',
              authService: fakeAuth,
            ),
          ),
        );

        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('first_login_new_password')),
            matching: find.byType(EditableText),
          ),
          '246810',
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('first_login_confirm_password')),
            matching: find.byType(EditableText),
          ),
          '246810',
        );

        await tester.tap(find.byKey(const Key('first_login_submit_button')));
        await tester.pumpAndSettle();

        expect(fakeAuth.callCount, 1);
        expect(fakeAuth.lastToken, 'change-tok-ok');
        expect(fakeAuth.lastNewPassword, '246810');
        expect(fakeAuth.lastConfirmPassword, '246810');
        expect(find.byType(LoginPhoneScreen), findsOneWidget);
        expect(find.byType(FirstLoginChangePasswordScreen), findsNothing);
      },
    );
  });
}
