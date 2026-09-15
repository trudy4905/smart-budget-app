/* ==========================================================================
   DAILY DETAIL TRANSACTION LIST ENGINE
   ========================================================================== */

import { state, isTransactionMatchingSelection, saveTransactions } from './state.js';
import { CATEGORIES } from './constants.js';
import { parseLocalDateStr, formatNumber, showToast } from './helpers.js';

export function renderDailyDetail(onRenderApp) {
  const titleEl = document.getElementById('selected-date-title');
  const sumEl = document.getElementById('selected-date-sum');
  const listEl = document.getElementById('transaction-list');

  if (!titleEl || !sumEl || !listEl) return;

  const dateObj = parseLocalDateStr(state.selectedDateStr);
  const month = dateObj.getMonth() + 1;
  const day = dateObj.getDate();
  const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
  
  let accSubTitle = state.selectedAccountIds.includes('all') ? '전체 계좌' : 
    (state.selectedAccountIds.length === 1 ? (state.accounts.find(a => a.id === state.selectedAccountIds[0])?.name || '') : `선택 계좌 ${state.selectedAccountIds.length}개`);
  titleEl.textContent = `${month}월 ${day}일 (${dayNames[dateObj.getDay()]})`;

  const dailyTxs = state.transactions.filter(t => t.date === state.selectedDateStr && isTransactionMatchingSelection(t));

  let dailyExpenseSum = 0;
  dailyTxs.forEach(t => {
    if (t.type === 'expense') dailyExpenseSum += Number(t.amount);
  });

  sumEl.textContent = `일일 지출: ₩${formatNumber(dailyExpenseSum)} (${accSubTitle})`;
  listEl.innerHTML = '';

  if (dailyTxs.length === 0) {
    listEl.innerHTML = `
      <div class="empty-state">
        <i data-lucide="file-plus-2"></i>
        <p>등록된 내역이 없습니다.<br>'+ 항목 추가'를 눌러 지출이나 적금을 기록해보세요!</p>
      </div>
    `;
    return;
  }

  dailyTxs.forEach(tx => {
    const itemEl = document.createElement('div');
    itemEl.className = 'tx-item';

    const categoryObj = CATEGORIES.find(c => c.name === tx.category) || { emoji: '📌', color: '#64748b' };
    const isExpense = tx.type === 'expense';
    const amountPrefix = isExpense ? '-' : '+';
    const amountClass = tx.type;

    const txAcc = state.accounts.find(a => a.id === tx.accountId) || { name: '미지정 계좌', bank: '', type: 'bank' };
    const accBadge = txAcc.type === 'card' ? (txAcc.cardKind === 'debit' ? '💳[체크]' : '💳[신용]') : '🏦';
    const recurringBadge = tx.isRecurring ? `<span class="badge-recurring-tag">🔄 고정</span>` : '';
    const settlementBadge = tx.isSettlement ? `<span class="badge-recurring-tag" style="background: rgba(236, 72, 153, 0.15); color: #ec4899;">💳 카드정산</span>` : '';

    itemEl.innerHTML = `
      <div class="tx-left">
        <div class="tx-icon-pill" style="background: ${categoryObj.color}20; color: ${categoryObj.color}">
          ${categoryObj.emoji}
        </div>
        <div class="tx-info">
          <span class="tx-title">${tx.memo || tx.category} ${recurringBadge} ${settlementBadge}</span>
          <div class="tx-meta">
            <span>${accBadge} ${txAcc.name}</span> • <span>${tx.category}</span> • <span>${tx.payment || '미지정'}</span>
          </div>
        </div>
      </div>
      <div class="tx-right">
        <span class="tx-amount ${amountClass}">${amountPrefix}₩${formatNumber(tx.amount)}</span>
        <button class="tx-delete-btn" data-id="${tx.id}" title="삭제">
          <i data-lucide="trash-2"></i>
        </button>
      </div>
    `;

    const deleteBtn = itemEl.querySelector('.tx-delete-btn');
    if (deleteBtn) {
      deleteBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        deleteTransaction(tx.id, onRenderApp);
      });
    }

    listEl.appendChild(itemEl);
  });
}

export function deleteTransaction(id, onRenderApp) {
  if (confirm('해당 내역을 삭제하시겠습니까?')) {
    state.transactions = state.transactions.filter(t => t.id !== id);
    saveTransactions();
    if (onRenderApp) onRenderApp();
    showToast('항목이 삭제되었습니다.');
  }
}
