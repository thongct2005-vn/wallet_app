class TransactionModel {
  final int id;
  final String type;
  final String direction;
  final String? description;
  final String counterpartyName;
  final String counterpartyPhone;
  final String counterpartyId;
  final num amount;
  final num fee;
  final String status;
  final DateTime createdAt;
  final num balanceBefore;
  final num balanceAfter;
  final String bankName;
  final String? orderId;
  final String fundingSource;
  final String? postpaidAction;
  final String? userMessage;

  TransactionModel({
    required this.id,
    required this.type,
    required this.direction,
    required this.description,
    required this.counterpartyName,
    required this.counterpartyPhone,
    required this.counterpartyId,
    required this.amount,
    required this.fee,
    required this.status,
    required this.createdAt,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.bankName,
    this.orderId,
    this.fundingSource = 'MAIN_WALLET',
    this.postpaidAction,
    this.userMessage,
  });

  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final direction = (json['direction'] ?? 'OUT').toString();
    final isOut = direction == 'OUT';
    return TransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: (json['transaction_type'] ?? '').toString(),
      direction: direction,
      description: json['description']?.toString(),
      counterpartyName: isOut
          ? (json['destination_display_name'] ?? 'Người nhận').toString()
          : (json['source_display_name'] ?? 'Người gửi').toString(),
      counterpartyPhone: isOut
          ? (json['destination_display_phone'] ?? '').toString()
          : (json['source_display_phone'] ?? '').toString(),
      counterpartyId: isOut
          ? (json['destination_user_id'] ?? '').toString()
          : (json['source_user_id'] ?? '').toString(),
      amount: num.tryParse(json['amount']?.toString() ?? '') ?? 0,
      fee: num.tryParse(json['fee']?.toString() ?? '') ?? 0,
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      balanceBefore:
          num.tryParse(json['balance_before']?.toString() ?? '') ?? 0,
      balanceAfter:
          num.tryParse(json['balance_after']?.toString() ?? '') ?? 0,
      bankName: (json['bank_name'] ?? '').toString(),
      orderId: json['order_id']?.toString(),
      fundingSource: (json['funding_source'] ?? 'MAIN_WALLET').toString(),
      postpaidAction: json['postpaid_action']?.toString(),
      userMessage: json['user_message']?.toString(),
    );
  }
}