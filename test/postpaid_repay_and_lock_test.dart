import 'dart:convert';
import 'dart:typed_data';

import 'package:app/src/postpaid/confirm_postpaid_repay_screen.dart';
import 'package:app/src/postpaid/postpaid_screen.dart';
import 'package:app/src/services/bank_service.dart';
import 'package:app/src/services/postpaid_service.dart';
import 'package:app/src/services/wallet_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturedRequest {
  final String method;
  final String path;
  final Map<String, dynamic> headers;
  final dynamic data;

  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.data,
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final payload = handler(options);
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeWalletService extends Fake implements WalletService {}

class _FakeBankService extends Fake implements BankService {}

PostpaidService _buildStubPostpaidService({
  required Map<String, dynamic> walletData,
  List<_CapturedRequest>? recorded,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local/api/v2'));
  dio.httpClientAdapter = _StubAdapter((options) {
    recorded?.add(
      _CapturedRequest(
        method: options.method,
        path: options.path,
        headers: Map<String, dynamic>.from(options.headers),
        data: options.data,
      ),
    );
    if (options.path.endsWith('/postpaid/wallet')) {
      return {'success': true, 'message': 'OK', 'data': walletData};
    }
    if (options.path.endsWith('/postpaid/entries')) {
      return {
        'success': true,
        'message': 'OK',
        'data': {'entries': <dynamic>[], 'next_cursor': null},
      };
    }
    if (options.path.endsWith('/postpaid/repay')) {
      return {
        'success': true,
        'message': 'Thanh toán dư nợ Ví trả sau thành công',
        'data': {'amount': 500000, 'mainBalanceAfter': 1000000},
      };
    }
    return {'success': true, 'message': 'OK', 'data': {}};
  });
  return PostpaidService(api: dio);
}

Map<String, dynamic> _baseFrozenWallet({
  required String lockReason,
  int overdueCount = 0,
  int usedAmount = 0,
  Map<String, dynamic>? latestUnlockRequest,
}) {
  return {
    'activated': true,
    'status': 'FROZEN',
    'lock_reason': lockReason,
    'overdue_count': overdueCount,
    'days_overdue': 0,
    'credit_limit': 2000000,
    'available_limit': 0,
    'used_amount': usedAmount,
    'billed_amount': 0,
    'service_fee_amount': 0,
    'late_fee_amount': 0,
    'main_balance': 3000000,
    'latest_unlock_request': latestUnlockRequest,
  };
}

void main() {
  test('PostpaidService.repayDebt sends MAIN_WALLET and BANK payloads properly', () async {
    final recorded = <_CapturedRequest>[];
    final service = _buildStubPostpaidService(
      walletData: _baseFrozenWallet(lockReason: 'USER_FREEZE'),
      recorded: recorded,
    );

    final mainRes = await service.repayDebt(
      amount: 500000,
      idempotencyKey: 'idem-main-1',
      pinToken: 'pin-main-1',
    );
    expect(mainRes['is_success'], isTrue);
    expect(recorded.last.headers['idempotency-key'], 'idem-main-1');
    expect(recorded.last.headers['x-pin-token'], 'pin-main-1');
    expect(recorded.last.data, {
      'amount': 500000,
      'funding_source': 'MAIN_WALLET',
    });

    final bankRes = await service.repayDebt(
      amount: 500000,
      idempotencyKey: 'idem-bank-2',
      pinToken: 'pin-bank-2',
      fundingSource: 'BANK',
      linkedBankAccountId: 'bank-acc-99',
    );
    expect(bankRes['is_success'], isTrue);
    expect(recorded.last.data, {
      'amount': 500000,
      'funding_source': 'BANK',
      'linked_bank_account_id': 'bank-acc-99',
    });
  });

  testWidgets('ConfirmPostpaidRepayScreen renders BANK funding selection cleanly', (
    tester,
  ) async {
    final service = _buildStubPostpaidService(
      walletData: _baseFrozenWallet(lockReason: 'USER_FREEZE'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmPostpaidRepayScreen(
          amount: 500000,
          mainBalance: 100000,
          initialFundingSource: 'BANK',
          initialLinkedBankAccountId: 'bank-1',
          initialLinkedBanks: const [
            {
              'id': 'bank-1',
              'bank_code': 'VCB',
              'bank_name': 'Vietcombank',
              'account_number_masked': '**** 1234',
              'is_show_balance': true,
              'balance': '2000000',
            },
          ],
          postpaidService: service,
          walletService: _FakeWalletService(),
          bankService: _FakeBankService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thanh toán dư nợ Ví trả sau'), findsOneWidget);
    expect(find.text('500.000đ'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PostpaidScreen USER_FREEZE renders single banner with quick unfreeze and enabled manage actions', (
    tester,
  ) async {
    final service = _buildStubPostpaidService(
      walletData: _baseFrozenWallet(lockReason: 'USER_FREEZE', usedAmount: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostpaidScreen(
          postpaidService: service,
          walletService: _FakeWalletService(),
          bankService: _FakeBankService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ví trả sau đang tạm khóa'), findsOneWidget);
    expect(find.text('Ví trả sau đang tạm khóa chi tiêu'), findsNothing);
    expect(find.byKey(const Key('btn-postpaid-quick-unfreeze')), findsOneWidget);
    expect(find.text('Mở khóa ví'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Quản lý Ví trả sau'), 200);
    await tester.tap(find.text('Quản lý Ví trả sau'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sheet-manage-postpaid-wallet')), findsOneWidget);
    final unfreezeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-unfreeze')),
    );
    final closeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-close')),
    );
    expect(unfreezeInk.onTap, isNotNull);
    expect(closeInk.onTap, isNotNull);
  });

  testWidgets('PostpaidScreen ADMIN_FREEZE hides self-unfreeze button and disables unfreeze/close in manage sheet', (
    tester,
  ) async {
    final service = _buildStubPostpaidService(
      walletData: _baseFrozenWallet(lockReason: 'ADMIN_FREEZE'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostpaidScreen(
          postpaidService: service,
          walletService: _FakeWalletService(),
          bankService: _FakeBankService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ví đã bị Quản trị viên tạm khóa'), findsOneWidget);
    expect(find.byKey(const Key('btn-postpaid-quick-unfreeze')), findsNothing);
    expect(find.text('Mở khóa ví'), findsNothing);

    await tester.scrollUntilVisible(find.text('Quản lý Ví trả sau'), 200);
    await tester.tap(find.text('Quản lý Ví trả sau'));
    await tester.pumpAndSettle();

    final unfreezeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-unfreeze')),
    );
    final closeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-close')),
    );
    expect(unfreezeInk.onTap, isNull);
    expect(closeInk.onTap, isNull);
  });

  testWidgets('PostpaidScreen OVERDUE_REPEAT shows proof unlock card, hides quick unfreeze, disables self actions in manage sheet', (
    tester,
  ) async {
    final service = _buildStubPostpaidService(
      walletData: _baseFrozenWallet(
        lockReason: 'OVERDUE_REPEAT',
        overdueCount: 2,
        latestUnlockRequest: const {
          'status': 'REJECTED',
          'proof_count': 2,
          'admin_note': 'Anh sao ke luong chua ro',
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PostpaidScreen(
          postpaidService: service,
          walletService: _FakeWalletService(),
          bankService: _FakeBankService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ví bị khóa do quá hạn lặp lại (Lần 2)'), findsOneWidget);
    expect(find.text('Phản hồi Admin: Anh sao ke luong chua ro'), findsOneWidget);
    expect(find.text('Gửi lại ảnh chứng minh thu nhập'), findsOneWidget);
    expect(find.byKey(const Key('btn-postpaid-quick-unfreeze')), findsNothing);

    await tester.scrollUntilVisible(find.text('Quản lý Ví trả sau'), 200);
    await tester.tap(find.text('Quản lý Ví trả sau'));
    await tester.pumpAndSettle();

    final unfreezeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-unfreeze')),
    );
    final closeInk = tester.widget<InkWell>(
      find.byKey(const Key('btn-manage-close')),
    );
    expect(unfreezeInk.onTap, isNull);
    expect(closeInk.onTap, isNull);
  });
}
