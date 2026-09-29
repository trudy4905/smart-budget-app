class Account {
  String id;
  String type; // 'bank', 'card'
  String name;
  String bank;
  String? accountNumber;
  int initialBalance;
  String? cardKind; // 'credit', 'debit'
  int? paymentDay;
  int? billingStartMonth; // 0 for current month, -1 for previous month
  int? billingStartDay;
  int? billingEndMonth;
  int? billingEndDay;
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
    this.billingStartMonth,
    this.billingStartDay,
    this.billingEndMonth,
    this.billingEndDay,
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
        'billingStartMonth': billingStartMonth,
        'billingStartDay': billingStartDay,
        'billingEndMonth': billingEndMonth,
        'billingEndDay': billingEndDay,
        'linkedBankAccountId': linkedBankAccountId,
        'color': color,
      };

  factory Account.fromJson(Map<String, dynamic> json) {
    // Legacy migration for credit cards: default to prev month 1 ~ prev month last day
    int? bStartMonth = json['billingStartMonth'];
    int? bStartDay = json['billingStartDay'];
    int? bEndMonth = json['billingEndMonth'];
    int? bEndDay = json['billingEndDay'];

    if (json['type'] == 'card' && json['cardKind'] == 'credit') {
      bStartMonth ??= -1;
      bStartDay ??= 1;
      bEndMonth ??= -1;
      bEndDay ??= 31; // 31 represents last day
    }

    return Account(
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
        billingStartMonth: bStartMonth,
        billingStartDay: bStartDay,
        billingEndMonth: bEndMonth,
        billingEndDay: bEndDay,
        linkedBankAccountId: json['linkedBankAccountId'],
        color: json['color'] ?? '#6366f1',
      );
  }
}
