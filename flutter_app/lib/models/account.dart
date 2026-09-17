class Account {
  String id;
  String type; // 'bank', 'card'
  String name;
  String bank;
  String? accountNumber;
  int initialBalance;
  String? cardKind; // 'credit', 'debit'
  int? paymentDay;
  String? linkedBankAccountId;
  String color;

  Account({
    required this.id,
    required this.type,
    required this.name,
    required this.bank,
    this.accountNumber,
    this.initialBalance = 0,
    this.cardKind,
    this.paymentDay,
    this.linkedBankAccountId,
    required this.color,
  });

  bool get isCredit => type == 'card' && cardKind == 'credit';
  bool get isDebit => type == 'card' && cardKind == 'debit';
  bool get isBank => type == 'bank';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'bank': bank,
        'accountNumber': accountNumber,
        'initialBalance': initialBalance,
        'cardKind': cardKind,
        'paymentDay': paymentDay,
        'linkedBankAccountId': linkedBankAccountId,
        'color': color,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] ?? '',
        type: json['type'] ?? 'bank',
        name: json['name'] ?? '',
        bank: json['bank'] ?? '',
        accountNumber: json['accountNumber'],
        initialBalance: (json['initialBalance'] ?? 0) is int
            ? json['initialBalance']
            : int.tryParse(json['initialBalance'].toString()) ?? 0,
        cardKind: json['cardKind'],
        paymentDay: json['paymentDay'],
        linkedBankAccountId: json['linkedBankAccountId'],
        color: json['color'] ?? '#6366f1',
      );
}
