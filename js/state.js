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

export function setEditingAccountId(id) {
  state.editingAccountId = id;
}

export function setCategoryChartInstance(instance) {
  state.categoryChartInstance = instance;
}

// --- FILTER HELPER ---
export function isTransactionMatchingSelection(t) {
  if (state.selectedAccountIds.includes('all') || state.selectedAccountIds.length === 0) return true;
  if (state.selectedAccountIds.includes(t.accountId)) return true;
  
  const txAcc = state.accounts.find(a => a.id === t.accountId);
  if (txAcc && txAcc.cardKind === 'debit' && txAcc.linkedBankAccountId) {
    if (state.selectedAccountIds.includes(txAcc.linkedBankAccountId)) return true;
  }
  return false;
}

// --- ACTIVE MONTH AUTO-FOCUS & PERSISTENCE ---
export function loadActiveViewDate() {
  const savedDateStr = localStorage.getItem(STORAGE_KEYS.LAST_DATE);
  if (savedDateStr) {
    state.selectedDateStr = savedDateStr;
    const d = parseLocalDateStr(savedDateStr);
    state.currentDate = new Date(d.getFullYear(), d.getMonth(), 1);
    return;
  }

  if (state.transactions && state.transactions.length > 0) {
    const sortedTxs = [...state.transactions].sort((a, b) => b.date.localeCompare(a.date));
    const latestTx = sortedTxs[0];
    if (latestTx && latestTx.date) {
      state.selectedDateStr = latestTx.date;
      const d = parseLocalDateStr(latestTx.date);
      state.currentDate = new Date(d.getFullYear(), d.getMonth(), 1);
      return;
    }
  }

  const now = new Date();
  state.currentDate = new Date(now.getFullYear(), now.getMonth(), 1);
  state.selectedDateStr = formatDate(now);
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
    { id: 'acc_main', type: 'bank', name: '주거래 통장', bank: '신한은행', accountNumber: '', initialBalance: 0, color: '#6366f1' }
  ];
}

export function getSampleRecurringRules() {
  return [];
}

export function getSampleTransactions() {
  return [];
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
