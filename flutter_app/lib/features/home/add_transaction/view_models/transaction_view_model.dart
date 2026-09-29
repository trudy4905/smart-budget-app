import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/core/services/storage_service.dart';


class TransactionViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Transaction> transactions = [];

  Future<void> init() async {
    final loaded = await _storageService.loadTransactions();
    if (loaded != null) {
      transactions = loaded;
    } else {
      transactions = _sampleTransactions();
      await _saveTransactions();
    }
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    await _storageService.saveTransactions(transactions);
  }

  void addTransaction(Transaction tx) {
    transactions.add(tx);
    _saveTransactions();
    notifyListeners();
  }

  void addTransactions(List<Transaction> txs) {
    transactions.addAll(txs);
    _saveTransactions();
    notifyListeners();
  }

  void deleteTransaction(String txId) {
    transactions.removeWhere((t) => t.id == txId);
    _saveTransactions();
    notifyListeners();
  }

  void deleteRecurringTransactions(String recurringId) {
    transactions.removeWhere((t) => t.recurringId == recurringId);
    _saveTransactions();
    notifyListeners();
  }

  void transferCategory(String oldName, String newName) {
    for (var t in transactions) {
      if (t.category == oldName) {
        t.category = newName;
      }
    }
    _saveTransactions();
    notifyListeners();
  }
  
  void clearTransactions() {
    transactions = [];
    _saveTransactions();
    notifyListeners();
  }

  List<Transaction> _sampleTransactions() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    return [
      Transaction(
        id: 'tx_sample_1',
        type: 'expense',
        amount: 8000,
        category: '식비',
        date: today,
        accountId: 'acc_1',
        memo: '점심식사',
      ),
      Transaction(
        id: 'tx_sample_1',
        type: 'income',
        amount: 3000000,
        category: '급여',
        date: '${now.year}-${now.month.toString().padLeft(2, '0')}-25',
        accountId: 'acc_1',
        isRecurring: true,
      ),
    ];
  }
}

