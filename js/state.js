/* ==========================================================================
   APP STATE & DATA PERSISTENCE
   ========================================================================== */

import { STORAGE_KEYS } from './constants.js';
import { parseLocalDateStr, formatDate } from './helpers.js';

const _initNow = new Date();

export const state = {
  currentDate: new Date(_initNow.getFullYear(), _initNow.getMonth(), 1),
  selectedDateStr: formatDate(_initNow),
  selectedAccountIds: ['all'],
  drawerFilter: 'all', // 'all', 'cash', 'card', 'total_expense'
  accounts: [],
  transactions: [],
  recurringRules: [],
  editingAccountId: null,
  categoryChartInstance: null
};

// --- STATE SETTERS / MUTATORS ---
export function setCurrentDate(d) {
  state.currentDate = d;
}

export function setSelectedDateStr(str) {
  state.selectedDateStr = str;
}

export function setSelectedAccountIds(ids) {
  state.selectedAccountIds = ids;
}

export function setDrawerFilter(filter) {
  state.drawerFilter = filter;
}

export function setEditingAccountId(id) {
  state.editingAccountId = id;
}

export function setCategoryChartInstance(instance) {
  state.categoryChartInstance = instance;
}

// --- FILTER HELPER ---
export function isTransactionMatchingSelection(t) {
  // 1. Filter by drawer filter menu mode
  const txAcc = state.accounts.find(a => a.id === t.accountId);
  const isCardTx = txAcc && txAcc.type === 'card' && txAcc.cardKind === 'credit';
  const isCashTx = !txAcc || txAcc.type === 'bank' || !txAcc.type || txAcc.cardKind === 'debit';

  if (state.drawerFilter === 'income') {
    if (t.type !== 'income') return false;
  } else if (state.drawerFilter === 'cash') {
    if (!isCashTx || t.type !== 'expense') return false;
  } else if (state.drawerFilter === 'card') {
    if (!isCardTx || t.type !== 'expense') return false;
  } else if (state.drawerFilter === 'total_expense') {
    if (t.type !== 'expense') return false;
  }

  // 2. Filter by selected accounts checklist
  if (state.selectedAccountIds.includes('all') || state.selectedAccountIds.length === 0) return true;
  if (state.selectedAccountIds.includes(t.accountId)) return true;
  
  if (txAcc && txAcc.cardKind === 'debit' && txAcc.linkedBankAccountId) {
    if (state.selectedAccountIds.includes(txAcc.linkedBankAccountId)) return true;
  }
  return false;
}

// --- ACTIVE MONTH AUTO-FOCUS & TODAY AUTO-SELECTION ---
export function loadActiveViewDate() {
  const now = new Date();
  state.currentDate = new Date(now.getFullYear(), now.getMonth(), 1);
  state.selectedDateStr = formatDate(now);
  saveActiveViewDate();
}

export function saveActiveViewDate() {
  localStorage.setItem(STORAGE_KEYS.LAST_DATE, state.selectedDateStr);
}

// --- LOCAL STORAGE & DATA LOADING ---
export function loadAccounts() {
  const data = localStorage.getItem(STORAGE_KEYS.ACC);
  if (data) {
    try {
      state.accounts = JSON.parse(data);
    } catch (e) {
      console.error('Failed to parse accounts data', e);
      state.accounts = getSampleAccounts();
      saveAccounts();
    }
  } else {
    state.accounts = getSampleAccounts();
    saveAccounts();
  }
}

export function saveAccounts() {
  localStorage.setItem(STORAGE_KEYS.ACC, JSON.stringify(state.accounts));
}

export function loadRecurringRules() {
  const data = localStorage.getItem(STORAGE_KEYS.REC);
  if (data) {
    try {
      state.recurringRules = JSON.parse(data);
    } catch (e) {
      console.error('Failed to parse recurring rules', e);
      state.recurringRules = getSampleRecurringRules();
      saveRecurringRules();
    }
  } else {
    state.recurringRules = getSampleRecurringRules();
    saveRecurringRules();
  }
}

export function saveRecurringRules() {
  localStorage.setItem(STORAGE_KEYS.REC, JSON.stringify(state.recurringRules));
}

export function loadTransactions() {
  const data = localStorage.getItem(STORAGE_KEYS.TX);
  if (data) {
    try {
      state.transactions = JSON.parse(data);
    } catch (e) {
      console.error('Failed to parse transactions', e);
      state.transactions = getSampleTransactions();
      saveTransactions();
    }
  } else {
    state.transactions = getSampleTransactions();
    saveTransactions();
  }
}

export function saveTransactions() {
  localStorage.setItem(STORAGE_KEYS.TX, JSON.stringify(state.transactions));
}

export function getSampleAccounts() {
  return [
    { id: 'acc_shinhan_bank', type: 'bank', name: '주거래 통장', bank: '신한은행', accountNumber: '110-123-4567', initialBalance: 5420000, color: '#6366f1' },
    { id: 'acc_shinhan_card', type: 'card', cardKind: 'credit', name: '신한 쏠 신용카드', bank: '신한카드', paymentDay: 25, linkedBankAccountId: 'acc_shinhan_bank', color: '#8b5cf6' },
    { id: 'acc_hyundai_card', type: 'card', cardKind: 'credit', name: '현대 ZERO 카드', bank: '현대카드', paymentDay: 25, linkedBankAccountId: 'acc_shinhan_bank', color: '#ec4899' },
    { id: 'acc_toss_bank', type: 'bank', name: '토스 비상금통장', bank: '토스뱅크', accountNumber: '1000-01-23456', initialBalance: 1200000, color: '#3b82f6' }
  ];
}

export function getSampleRecurringRules() {
  return [];
}

export function getSampleTransactions() {
  const yr = 2026;
  const mo = '09';
  return [
    { id: 'tx_s1', date: `${yr}-${mo}-01`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 2091, category: '식당', memo: '식비 💰 -2091', payment: '계좌이체' },
    { id: 'tx_s2', date: `${yr}-${mo}-01`, accountId: 'acc_shinhan_card', type: 'expense', amount: 4500, category: '카페/디저트', memo: 'er, 커피', payment: '신용카드' },
    { id: 'tx_s3', date: `${yr}-${mo}-03`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: '서울대', payment: '기타' },
    { id: 'tx_s4', date: `${yr}-${mo}-04`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: '국보연', payment: '기타' },
    { id: 'tx_s5', date: `${yr}-${mo}-07`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 211, category: '식당', memo: '간식 💰 -211', payment: '현금' },
    { id: 'tx_s6', date: `${yr}-${mo}-08`, accountId: 'acc_toss_bank', type: 'expense', amount: 35000, category: '기타', memo: '이자(마통)', payment: '계좌이체' },
    { id: 'tx_s7', date: `${yr}-${mo}-09`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: 'kisa 간담회', payment: '기타' },
    { id: 'tx_s8', date: `${yr}-${mo}-09`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '기타', memo: '수료 연구', payment: '기타' },
    { id: 'tx_s9', date: `${yr}-${mo}-09`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 50000, category: '기타', memo: '출금', payment: '현금' },
    { id: 'tx_s10', date: `${yr}-${mo}-10`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 32000, category: '식당', memo: '저녁 약속', payment: '계좌이체' },
    { id: 'tx_s11', date: `${yr}-${mo}-10`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '기타', memo: 'RND 수행', payment: '기타' },
    { id: 'tx_s12', date: `${yr}-${mo}-11`, accountId: 'acc_shinhan_card', type: 'expense', amount: 18500, category: '교통/차량', memo: '가스비-', payment: '신용카드' },
    { id: 'tx_s13', date: `${yr}-${mo}-11`, accountId: 'acc_toss_bank', type: 'expense', amount: 17000, category: '문화/쇼핑', memo: '폰(넷플릭스)', payment: '계좌이체' },
    { id: 'tx_s14', date: `${yr}-${mo}-11`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 45000, category: '식당', memo: '오빠랑 데이트', payment: '계좌이체' },
    { id: 'tx_s15', date: `${yr}-${mo}-11`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: '창경궁', payment: '기타' },
    { id: 'tx_s16', date: `${yr}-${mo}-12`, accountId: 'acc_hyundai_card', type: 'expense', amount: 12000, category: '교통/차량', memo: '수도(홀릭)', payment: '신용카드' },
    { id: 'tx_s17', date: `${yr}-${mo}-12`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '식당', memo: 'bob 잠실 14시', payment: '기타' },
    { id: 'tx_s18', date: `${yr}-${mo}-12`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 100000, category: '기타', memo: '경호 결혼 13시', payment: '계좌이체' },
    { id: 'tx_s19', date: `${yr}-${mo}-14`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 2133, category: '식당', memo: '편의점 💰 -2133', payment: '현금' },
    { id: 'tx_s20', date: `${yr}-${mo}-14`, accountId: 'acc_toss_bank', type: 'expense', amount: 450000, category: '기타', memo: '전월 카드', payment: '계좌이체' },
    { id: 'tx_s21', date: `${yr}-${mo}-16`, accountId: 'acc_shinhan_bank', type: 'income', amount: 3500000, category: '수입/월급', memo: '9월 급여', payment: '계좌이체' },
    { id: 'tx_s22', date: `${yr}-${mo}-17`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '기타', memo: '석사과정', payment: '기타' },
    { id: 'tx_s23', date: `${yr}-${mo}-18`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 40000, category: '식당', memo: '저녁 약속', payment: '계좌이체' },
    { id: 'tx_s24', date: `${yr}-${mo}-19`, accountId: 'acc_shinhan_card', type: 'expense', amount: 185000, category: '교통/차량', memo: '관리비-', payment: '신용카드' },
    { id: 'tx_s25', date: `${yr}-${mo}-19`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 35000, category: '문화/쇼핑', memo: '남한산성 데이트', payment: '계좌이체' },
    { id: 'tx_s26', date: `${yr}-${mo}-20`, accountId: 'acc_shinhan_card', type: 'expense', amount: 23900, category: '교통/차량', memo: '코웨이', payment: '신용카드' },
    { id: 'tx_s27', date: `${yr}-${mo}-20`, accountId: 'acc_toss_bank', type: 'expense', amount: 55000, category: '기타', memo: '교보(생명)', payment: '계좌이체' },
    { id: 'tx_s28', date: `${yr}-${mo}-20`, accountId: 'acc_toss_bank', type: 'expense', amount: 120000, category: '기타', memo: '이자(주택)', payment: '계좌이체' },
    { id: 'tx_s29', date: `${yr}-${mo}-20`, accountId: 'acc_toss_bank', type: 'expense', amount: 500000, category: '적금/저축', memo: '적금-1', payment: '계좌이체' },
    { id: 'tx_s30', date: `${yr}-${mo}-21`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 14500, category: '교통/차량', memo: '💰 ?? 💳?', payment: '현금' },
    { id: 'tx_s31', date: `${yr}-${mo}-21`, accountId: 'acc_toss_bank', type: 'expense', amount: 33000, category: '기타', memo: 'SKB(인터넷)', payment: '계좌이체' },
    { id: 'tx_s32', date: `${yr}-${mo}-21`, accountId: 'acc_toss_bank', type: 'expense', amount: 42000, category: '기타', memo: '메리츠(보험)', payment: '계좌이체' },
    { id: 'tx_s33', date: `${yr}-${mo}-22`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: '세나퀴즈 미팅', payment: '기타' },
    { id: 'tx_s34', date: `${yr}-${mo}-24`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 58000, category: '교통/차량', memo: '추석 연휴', payment: '계좌이체' },
    { id: 'tx_s35', date: `${yr}-${mo}-25`, accountId: 'acc_shinhan_card', type: 'expense', amount: 4990, category: '장보기', memo: '쿠팡-09', payment: '신용카드' },
    { id: 'tx_s36', date: `${yr}-${mo}-25`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 300000, category: '기타', memo: '추석', payment: '계좌이체' },
    { id: 'tx_s37', date: `${yr}-${mo}-26`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 80000, category: '식당', memo: '추석 연휴', payment: '계좌이체' },
    { id: 'tx_s38', date: `${yr}-${mo}-27`, accountId: 'acc_toss_bank', type: 'income', amount: 25000, category: '부수입', memo: '러그빼기 거래', payment: '계좌이체' },
    { id: 'tx_s39', date: `${yr}-${mo}-28`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 68400, category: '장보기', memo: '💰 ??', payment: '현금' },
    { id: 'tx_s40', date: `${yr}-${mo}-30`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '문화/쇼핑', memo: '집코노미 박람회', payment: '기타' },
    { id: 'tx_s41', date: `${yr}-${mo}-30`, accountId: 'acc_shinhan_card', type: 'expense', amount: 54000, category: '교통/차량', memo: '교통비-', payment: '신용카드' },
    { id: 'tx_s42', date: `${yr}-${mo}-30`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 15000, category: '식당', memo: '💰 ??', payment: '현금' },
    { id: 'tx_s43', date: `${yr}-${mo}-30`, accountId: 'acc_shinhan_bank', type: 'expense', amount: 0, category: '기타', memo: '국군의날', payment: '기타' }
  ];
}

// --- RECURRING & SETTLEMENT ENGINE ---
export function applyRecurringRulesForDate(targetDateObj) {
  const year = targetDateObj.getFullYear();
  const month = targetDateObj.getMonth();
  const monthStr = String(month + 1).padStart(2, '0');

  let addedCount = 0;

  state.recurringRules.forEach(rule => {
    const targetDayStr = String(rule.dayOfMonth).padStart(2, '0');
    const targetDateStr = `${year}-${monthStr}-${targetDayStr}`;

    const exists = state.transactions.some(t => t.recurringId === rule.id && t.date === targetDateStr);

    if (!exists) {
      const newTx = {
        id: `tx_rec_${rule.id}_${year}_${monthStr}`,
        date: targetDateStr,
        accountId: rule.accountId,
        type: rule.type,
        amount: rule.amount,
        category: rule.category,
        payment: rule.payment,
        memo: rule.memo,
        isRecurring: true,
        recurringId: rule.id
      };

      state.transactions.push(newTx);
      addedCount++;
    }
  });

  if (addedCount > 0) {
    saveTransactions();
  }
}

export function applyRecurringRules() {
  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();
  
  applyRecurringRulesForDate(new Date(year, month - 1, 1));
  applyRecurringRulesForDate(new Date(year, month, 1));
  applyRecurringRulesForDate(new Date(year, month + 1, 1));
}

export function checkAutoCardSettlements() {
  const today = new Date();
  const year = today.getFullYear();
  const month = today.getMonth();
  const day = today.getDate();

  state.accounts.filter(a => a.type === 'card' && a.cardKind === 'credit' && a.linkedBankAccountId).forEach(card => {
    if (Number(card.paymentDay) === day) {
      const monthStr = String(month + 1).padStart(2, '0');
      const dayStr = String(day).padStart(2, '0');
      const settlementDateStr = `${year}-${monthStr}-${dayStr}`;
      const settlementId = `settle_${card.id}_${year}_${monthStr}`;

      const alreadySettled = state.transactions.some(t => t.id === settlementId);
      if (!alreadySettled) {
        const cardBillAmount = getCardBillForMonth(card.id, year, month);
        if (cardBillAmount > 0) {
          const settleTx = {
            id: settlementId,
            date: settlementDateStr,
            accountId: card.linkedBankAccountId,
            type: 'expense',
            amount: cardBillAmount,
            category: '기타',
            payment: '계좌이체',
            memo: `💳 ${card.name} 카드 대금 자동 출금 (정산)`,
            isSettlement: true
          };
          state.transactions.unshift(settleTx);
          saveTransactions();
        }
      }
    }
  });
}

export function getCardBillForMonth(cardId, year, month) {
  return state.transactions.filter(t => {
    const d = parseLocalDateStr(t.date);
    return t.accountId === cardId && d.getFullYear() === year && d.getMonth() === month && t.type === 'expense';
  }).reduce((sum, t) => sum + Number(t.amount || 0), 0);
}
