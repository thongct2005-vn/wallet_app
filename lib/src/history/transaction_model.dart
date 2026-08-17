class TransactionModel {
  final int id;
  final String type;
  final String direction;
  final String? description;
  final String counterpartyName;
  final num amount;
  final num fee;
  final String status;
  final DateTime createdAt;
  final num balanceBefore;
  final num balanceAfter;

  TransactionModel({
    required this.id,
    required this.type,
    required this.direction,
    required this.description,
    required this.counterpartyName,
    required this.amount,
    required this.fee,
    required this.status,
    required this.createdAt,
    required this.balanceBefore,
    required this.balanceAfter,
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
          ? (json['destination_display_name'] ??
                json['destination_display_phone'] ??
                'Người nhận')
          : (json['source_display_name'] ??
                json['source_display_phone'] ??
                'Người gửi'),
      amount: num.tryParse(json['amount']) ?? 0,
      fee: num.tryParse(json['fee']) ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      balanceBefore: num.tryParse(json['balance_before']) ?? 0,
      balanceAfter: num.tryParse(json['balance_after']) ?? 0,
    );
  }
}
