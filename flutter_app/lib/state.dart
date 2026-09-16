import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Account {
  String id;
  String type; // 'bank', 'card'
  String? bankName;
  String? initialBalance;
  String? cardKind; // 'credit', 'debit'
  String? cardName;
  String? linkedBankId;
  String? billingDate;
  String color;

  Account({
    required this.id,
    required this.type,
    this.bankName,
    this.initialBalance,
    this.cardKind,
    this.cardName,
    this.linkedBankId,
    this.billingDate,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'bankName': bankName,
        'initialBalance': initialBalance,
        'cardKind': cardKind,
        'cardName': cardName,
        'linkedBankId': linkedBankId,
        'billingDate': billingDate,
        'color': color,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        type: json['type'],
        bankName: json['bankName'],
        initialBalance: json['initialBalance'],
        cardKind: json['cardKind'],
        cardName: json['cardName'],
        linkedBankId: json['linkedBankId'],
        billingDate: json['billingDate'],
        color: json['color'] ?? '#6366f1',
      );
}

class Transaction {
  String id;
  String type; // 'income', 'expense'
  String date; // YYYY-MM-DD
  String amount;
  String category;
  String memo;
  String accountId;

  Transaction({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.category,
    required this.memo,
    required this.accountId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'date': date,
        'amount': amount,
        'category': category,
        'memo': memo,
        'accountId': accountId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        type: json['type'],
        date: json['date'],
        amount: json['amount'],
        category: json['category'],
        memo: json['memo'],
        accountId: json['accountId'],
      );
}

class AppState extends ChangeNotifier {
  List<Account> accounts = [];
  List<Transaction> transactions = [];
  String monthlyBudget = '';
  DateTime currentDate = DateTime.now();
  List<String> selectedAccountIds = ['all']; // 'all' or specific IDs

  AppState() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final accStr = prefs.getString('accounts');
    if (accStr != null) {
      final List dec = jsonDecode(accStr);
      accounts = dec.map((e) => Account.fromJson(e)).toList();
    }
    
    final txStr = prefs.getString('transactions');
    if (txStr != null) {
      final List dec = jsonDecode(txStr);
      transactions = dec.map((e) => Transaction.fromJson(e)).toList();
    }
    
    monthlyBudget = prefs.getString('monthlyBudget') ?? '';
    
    notifyListeners();
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', jsonEncode(accounts.map((e) => e.toJson()).toList()));
    await prefs.setString('transactions', jsonEncode(transactions.map((e) => e.toJson()).toList()));
    await prefs.setString('monthlyBudget', monthlyBudget);
    notifyListeners();
  }

  void addAccount(Account acc) {
    accounts.add(acc);
    saveState();
  }

  void updateAccount(Account acc) {
    final idx = accounts.indexWhere((e) => e.id == acc.id);
    if (idx != -1) {
      accounts[idx] = acc;
      saveState();
    }
  }

  void deleteAccount(String id) {
    accounts.removeWhere((e) => e.id == id);
    saveState();
  }

  void addTransaction(Transaction tx) {
    transactions.add(tx);
    saveState();
  }
}
