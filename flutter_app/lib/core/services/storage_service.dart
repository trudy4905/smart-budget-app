import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/features/accounts/models/account.dart';
import 'package:flutter_app/features/transactions/models/transaction.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';

const kStorageKeyTx = 'smart_budget_transactions_v6.0';
const kStorageKeyAcc = 'smart_budget_accounts_v6.0';
const kStorageKeyRec = 'smart_budget_recurring_v6.0';
const kStorageKeyCat = 'smart_budget_categories_v6.0';
const kStorageKeyOrder = 'dashboardItemOrder';

class StorageService {
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<List<Account>?> loadAccounts() async {
    final prefs = await _prefs;
    final str = prefs.getString(kStorageKeyAcc);
    if (str != null) {
      try {
        final List dec = jsonDecode(str);
        return dec.map((e) => Account.fromJson(e)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await _prefs;
    await prefs.setString(kStorageKeyAcc, jsonEncode(accounts.map((e) => e.toJson()).toList()));
  }

  Future<List<Transaction>?> loadTransactions() async {
    final prefs = await _prefs;
    final str = prefs.getString(kStorageKeyTx);
    if (str != null) {
      try {
        final List dec = jsonDecode(str);
        return dec.map((e) => Transaction.fromJson(e)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await _prefs;
    await prefs.setString(kStorageKeyTx, jsonEncode(transactions.map((e) => e.toJson()).toList()));
  }

  Future<List<CategoryInfo>?> loadCategories() async {
    final prefs = await _prefs;
    final str = prefs.getString(kStorageKeyCat);
    if (str != null) {
      try {
        final List dec = jsonDecode(str);
        return dec.map((e) => CategoryInfo.fromJson(e)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveCategories(List<CategoryInfo> categories) async {
    final prefs = await _prefs;
    await prefs.setString(kStorageKeyCat, jsonEncode(categories.map((e) => e.toJson()).toList()));
  }

  Future<List<String>?> loadDashboardItemOrder() async {
    final prefs = await _prefs;
    final str = prefs.getString(kStorageKeyOrder);
    if (str != null) {
      try {
        final List dec = jsonDecode(str);
        return List<String>.from(dec);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveDashboardItemOrder(List<String> order) async {
    final prefs = await _prefs;
    await prefs.setString(kStorageKeyOrder, jsonEncode(order));
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
