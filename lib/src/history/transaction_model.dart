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
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final direction = json['direction'] as String;
    final isOut = direction == 'OUT';
    return TransactionModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      type: json['transaction_type'] ?? '',
      direction: direction,
      description: json['description'],
      counterpartyName: isOut
          ? (json['destination_display_name'] ?? 'Người nhận')
          : (json['source_display_name'] ?? 'Người gửi'),
      counterpartyPhone: isOut
          ? json['destination_display_phone'] ?? ''
          : json['source_display_phone'] ?? '',
      counterpartyId: isOut
          ? json['destination_user_id'] ?? ''
          : json['source_user_id'] ?? '',
      amount: num.tryParse(json['amount']) ?? 0,
      fee: num.tryParse(json['fee']) ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      balanceBefore: num.tryParse(json['balance_before']) ?? 0,
      balanceAfter: num.tryParse(json['balance_after']) ?? 0,
      bankName: json['bank_name'] ?? '',
    );
  }
}
