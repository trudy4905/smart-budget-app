class Transaction {
  String id;
  String date; // YYYY-MM-DD
  String accountId;
  String type; // 'income', 'expense'
  int amount;
  String category;
  String memo;
  String payment;
  bool isRecurring;
  String? recurringId;
  bool isSettlement;

  Transaction({
    required this.id,
    required this.date,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.category,
    this.memo = '',
    this.payment = '',
    this.isRecurring = false,
    this.recurringId,
    this.isSettlement = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'accountId': accountId,
        'type': type,
        'amount': amount,
        'category': category,
        'memo': memo,
        'payment': payment,
        'isRecurring': isRecurring,
        'recurringId': recurringId,
        'isSettlement': isSettlement,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] ?? '',
        date: json['date'] ?? '',
        accountId: json['accountId'] ?? '',
        type: json['type'] ?? 'expense',
        amount: (json['amount'] ?? 0) is int
            ? json['amount']
            : int.tryParse(json['amount'].toString()) ?? 0,
        category: json['category'] ?? '기타',
        memo: json['memo'] ?? '',
        payment: json['payment'] ?? '',
        isRecurring: json['isRecurring'] ?? false,
        recurringId: json['recurringId'],
        isSettlement: json['isSettlement'] ?? false,
      );
}

// ============================================================
// APP STATE
// ============================================================
