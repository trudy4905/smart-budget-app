import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/asset_detail/view_models/asset_detail_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('카드 결제대금이 cashDebitPaidList에 중복되지 않고 paidCardList에만 반영되는지 검증', () {
    final accVM = AccountViewModel();
    final txVM = TransactionViewModel();
    final uiVM = UiViewModel();

    final bankAcc = Account(
      id: 'bank_1',
      type: 'bank',
      name: '국민은행',
      bank: '국민',
      initialBalance: 1000000,
      color: '#6366f1',
    );

    final creditCard = Account(
      id: 'card_1',
      type: 'card',
      cardKind: 'credit',
      name: '현대카드',
      bank: '현대',
      paymentDay: 25,
      billingStartMonth: -1,
      billingStartDay: 1,
      billingEndMonth: -1,
      billingEndDay: 31,
      linkedBankAccountId: 'bank_1',
      color: '#ec4899',
    );

    accVM.accounts = [bankAcc, creditCard];

    // 2026-09월 카드 사용 내역 (10월 25일 결제분)
    final cardExpense = Transaction(
      id: 'tx_card_1',
      date: '2026-09-15',
      accountId: 'card_1',
      type: 'expense',
      amount: 50000,
      category: '식비',
      memo: '점심',
    );

    // 2026-10월 은행 지출 내역
    final bankExpense = Transaction(
      id: 'tx_bank_1',
      date: '2026-10-10',
      accountId: 'bank_1',
      type: 'expense',
      amount: 20000,
      category: '교통',
      memo: '버스',
    );

    txVM.transactions = [cardExpense, bankExpense];

    final dashboardVM = DashboardViewModel(accVM, txVM, uiVM);

    // 2026년 10월 요약 조회
    final summary = dashboardVM.getDashboardSummary(2026, 10);

    // 1. 은행 지출 내역에는 오직 순수 은행 지출만 있어야 함 (카드대금 50,000원이 섞이지 않음)
    expect(summary.alreadyPaidCashDebit, 20000);
    expect(summary.alreadyPaidCashDebitList.length, 1);
    expect(summary.alreadyPaidCashDebitList.first.id, 'tx_bank_1');

    // 2. 카드대금은 paidCardList에 정상 계산되어 있어야 함
    final allCardPayments = [...summary.alreadyPaidCardList, ...summary.upcomingCardPayments];
    expect(allCardPayments.any((c) => c.account.id == 'card_1' && c.amount == 50000), isTrue);

    // 3. getTransactionsForMonth(2026, 10)에는 원본 거래(tx_bank_1)만 있고 가상 대금이 없어야 함
    final monthTxs = dashboardVM.getTransactionsForMonth(2026, 10);
    expect(monthTxs.length, 1);
    expect(monthTxs.first.id, 'tx_bank_1');
  });

  test('상세보기 카테고리 소비 통계에 카드 사용 및 고정지출이 모두 정상 집계되는지 검증', () {
    final accVM = AccountViewModel();
    final txVM = TransactionViewModel();
    final uiVM = UiViewModel();
    final catVM = CategoryViewModel();

    final bankAcc = Account(
      id: 'bank_1',
      type: 'bank',
      name: '국민은행',
      bank: '국민',
      initialBalance: 1000000,
      color: '#6366f1',
    );

    final creditCard = Account(
      id: 'card_1',
      type: 'card',
      cardKind: 'credit',
      name: '현대카드',
      bank: '현대',
      paymentDay: 25,
      billingStartMonth: -1,
      billingStartDay: 1,
      billingEndMonth: -1,
      billingEndDay: 31,
      linkedBankAccountId: 'bank_1',
      color: '#ec4899',
    );

    accVM.accounts = [bankAcc, creditCard];

    // 2026-10월 일반 카드 지출 (식비)
    final cardExpense = Transaction(
      id: 'tx_1',
      date: '2026-10-05',
      accountId: 'card_1',
      type: 'expense',
      amount: 40000,
      category: '식비',
      memo: '점심식사',
    );

    // 2026-10월 고정지출 (통신비)
    final fixedExpense = Transaction(
      id: 'tx_2',
      date: '2026-10-15',
      accountId: 'bank_1',
      type: 'expense',
      amount: 60000,
      category: '통신비',
      memo: '휴대폰요금',
      isRecurring: true,
      recurringId: 'rec_phone',
    );

    // 2026-10월 고정지출 ('~대금'이 붙은 아파트 관리비)
    final billExpense = Transaction(
      id: 'tx_3',
      date: '2026-10-20',
      accountId: 'bank_1',
      type: 'expense',
      amount: 150000,
      category: '관리비 대금',
      memo: '관리비',
      isRecurring: true,
      recurringId: 'rec_maint',
    );

    txVM.transactions = [cardExpense, fixedExpense, billExpense];

    final dashboardVM = DashboardViewModel(accVM, txVM, uiVM);
    final assetDetailVM = AssetDetailViewModel(
      dashboardVM: dashboardVM,
      categoryVM: catVM,
    );

    assetDetailVM.selectDate(DateTime(2026, 10, 1));
    final selectedData = assetDetailVM.getSelectedData();

    // 카테고리별 소비 통계에 3개 카테고리가 모두 정상 집계되어야 함!
    // ('관리비 대금'도 정상 소비로 집계되고, 카드 지출 '식비'도 정상 집계됨)
    final spendings = selectedData.categorySpendings;
    expect(spendings.length, 3);

    final maintItem = spendings.firstWhere((s) => s.category == '관리비 대금');
    expect(maintItem.amount, 150000);

    final phoneItem = spendings.firstWhere((s) => s.category == '통신비');
    expect(phoneItem.amount, 60000);

    final foodItem = spendings.firstWhere((s) => s.category == '식비');
    expect(foodItem.amount, 40000);

    // 총 소비 합계 = 150,000 + 60,000 + 40,000 = 250,000원
    final totalSpent = spendings.fold(0, (s, i) => s + i.amount);
    expect(totalSpent, 250000);
  });
}
