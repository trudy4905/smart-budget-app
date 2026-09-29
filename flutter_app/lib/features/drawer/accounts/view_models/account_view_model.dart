import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/core/services/storage_service.dart';

class AccountViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Account> accounts = [];

  Future<void> init() async {
    final loaded = await _storageService.loadAccounts();
    if (loaded != null) {
      accounts = loaded;
    } else {
      accounts = _sampleAccounts();
      await _saveAccounts();
    }
    notifyListeners();
  }

  Future<void> _saveAccounts() async {
    await _storageService.saveAccounts(accounts);
  }

  void addAccount(Account account) {
    accounts.add(account);
    _saveAccounts();
    notifyListeners();
  }

  void updateAccount(Account account) {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      accounts[idx] = account;
      _saveAccounts();
      notifyListeners();
    }
  }

  void deleteAccount(String accountId) {
    accounts.removeWhere((a) => a.id == accountId);
    _saveAccounts();
    notifyListeners();
  }

  void clearAccounts() {
    accounts = _sampleAccounts();
    _saveAccounts();
    notifyListeners();
  }

  List<Account> _sampleAccounts() {
    return [
      Account(id: 'acc_1', name: '월급통장', type: 'bank', color: '#3B82F6', initialBalance: 0, bank: 'KB국민'),
      Account(id: 'acc_2', name: '생활비카드', type: 'credit', color: '#EF4444', initialBalance: 0, bank: '신한카드', linkedBankAccountId: 'acc_1'),
    ];
  }
}

