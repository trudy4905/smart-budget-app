/* ==========================================================================
   SETTINGS VIEW ENGINE
   ========================================================================== */

import { state, setSelectedAccountIds, getCardBillForMonth, saveAccounts, saveRecurringRules, saveTransactions } from './state.js';
import { formatNumber, formatDate, showToast } from './helpers.js';
import { openAccModal } from './modals.js';

export function renderSettingsView(onRenderApp) {
  const bankListEl = document.getElementById('bank-account-manage-list');
  const cardListEl = document.getElementById('card-account-manage-list');
  const recListEl = document.getElementById('recurring-manage-list');

  if (!bankListEl || !cardListEl || !recListEl) return;

  bankListEl.innerHTML = '';
  cardListEl.innerHTML = '';

  const bankAccounts = state.accounts.filter(a => a.type === 'bank' || !a.type);
  const cardAccounts = state.accounts.filter(a => a.type === 'card');

  if (bankAccounts.length === 0) {
    bankListEl.innerHTML = `<div class="empty-state" style="padding: 12px;"><p>등록된 입출금 통장이 없습니다.</p></div>`;
  } else {
    bankAccounts.forEach(acc => {
      const isSelected = state.selectedAccountIds.includes('all') || state.selectedAccountIds.includes(acc.id);
      const initBal = Number(acc.initialBalance || 0);

      const item = document.createElement('div');
      item.className = `account-manage-item ${isSelected ? 'active' : ''}`;
      item.innerHTML = `
        <div class="acc-manage-info">
          <span class="acc-color-dot" style="background: ${acc.color || '#6366f1'}"></span>
          <div>
            <div class="acc-manage-title">🏦 ${acc.name}</div>
            <div class="acc-manage-sub">${acc.bank} ${acc.accountNumber ? '• ' + acc.accountNumber : ''}</div>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          <span class="acc-manage-balance" style="font-size: 0.82rem; color: var(--text-muted);">(초기 설정금액: ₩${formatNumber(initBal)})</span>
          <button class="action-btn-sm edit-acc-btn" data-id="${acc.id}" title="통장 정보 수정" style="padding: 4px 10px; border-radius: 12px; font-size: 0.78rem; border: 1px solid var(--primary); color: var(--primary); background: transparent; display: flex; align-items: center; gap: 4px; font-weight: 600; cursor: pointer;">
            <i data-lucide="pencil" style="width: 12px; height: 12px;"></i> 수정
          </button>
          <button class="tx-delete-btn delete-acc-btn" data-id="${acc.id}" title="통장 삭제">
            <i data-lucide="trash-2"></i>
          </button>
        </div>
      `;

      item.addEventListener('click', (e) => {
        if (!e.target.closest('.delete-acc-btn')) {
          openAccModal('bank', acc);
        }
      });

      const editBtn = item.querySelector('.edit-acc-btn');
      if (editBtn) {
        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          openAccModal('bank', acc);
        });
      }

      const deleteBtn = item.querySelector('.delete-acc-btn');
      if (deleteBtn) {
        deleteBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          deleteAccount(acc.id, onRenderApp);
        });
      }

      bankListEl.appendChild(item);
    });
  }

  if (cardAccounts.length === 0) {
    cardListEl.innerHTML = `<div class="empty-state" style="padding: 12px;"><p>등록된 카드가 없습니다.</p></div>`;
  } else {
    cardAccounts.forEach(acc => {
      const isSelected = state.selectedAccountIds.includes('all') || state.selectedAccountIds.includes(acc.id);
      const isCredit = acc.cardKind === 'credit';
      const typeBadge = isCredit ? `<span class="acc-type-badge card">신용카드</span>` : `<span class="acc-type-badge bank" style="background: rgba(6, 182, 212, 0.15); color: #06b6d4;">체크카드</span>`;

      const linkedBank = state.accounts.find(a => a.id === acc.linkedBankAccountId);
      const linkedName = linkedBank ? ` ➔ ${linkedBank.name}` : '';

      const balanceDisplayHtml = isCredit
        ? `<span class="acc-manage-balance" style="font-size: 0.82rem; color: var(--text-muted);">결제일: 매월 ${acc.paymentDay || 25}일</span>`
        : ``;

      const item = document.createElement('div');
      item.className = `account-manage-item ${isSelected ? 'active' : ''}`;
      item.innerHTML = `
        <div class="acc-manage-info">
          <span class="acc-color-dot" style="background: ${acc.color || '#ec4899'}"></span>
          <div>
            <div class="acc-manage-title">💳 ${acc.name} ${typeBadge}</div>
            <div class="acc-manage-sub">${acc.bank} ${acc.accountNumber ? '• ' + acc.accountNumber : ''}${linkedName}</div>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 8px;">
          ${balanceDisplayHtml}
          <button class="action-btn-sm edit-acc-btn" data-id="${acc.id}" title="카드 정보 수정" style="padding: 4px 10px; border-radius: 12px; font-size: 0.78rem; border: 1px solid var(--primary); color: var(--primary); background: transparent; display: flex; align-items: center; gap: 4px; font-weight: 600; cursor: pointer;">
            <i data-lucide="pencil" style="width: 12px; height: 12px;"></i> 수정
          </button>
          <button class="tx-delete-btn delete-acc-btn" data-id="${acc.id}" title="카드 삭제">
            <i data-lucide="trash-2"></i>
          </button>
        </div>
      `;

      item.addEventListener('click', (e) => {
        if (!e.target.closest('.delete-acc-btn') && !e.target.closest('.settle-card-btn')) {
          openAccModal('card', acc);
        }
      });

      const editBtn = item.querySelector('.edit-acc-btn');
      if (editBtn) {
        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          openAccModal('card', acc);
        });
      }

      const deleteBtn = item.querySelector('.delete-acc-btn');
      if (deleteBtn) {
        deleteBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          deleteAccount(acc.id, onRenderApp);
        });
      }

      const settleBtn = item.querySelector('.settle-card-btn');
      if (settleBtn) {
        settleBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          manualSettleCardBill(acc.id, onRenderApp);
        });
      }

      cardListEl.appendChild(item);
    });
  }

  recListEl.innerHTML = '';
  if (state.recurringRules.length === 0) {
    recListEl.innerHTML = `
      <div class="empty-state" style="padding: 16px 0;">
        <p>등록된 고정 지출/수입 내역이 없습니다.<br>거래 입력 시 '매월 이 날짜에 자동 등록'을 선택해보세요!</p>
      </div>
    `;
  } else {
    state.recurringRules.forEach(rule => {
      const acc = state.accounts.find(a => a.id === rule.accountId) || { name: '계좌' };
      const isExpense = rule.type === 'expense';
      const typeBadge = isExpense ? '🔴 지출' : '🟢 수입';

      const item = document.createElement('div');
      item.className = 'recurring-manage-item';
      item.innerHTML = `
        <div class="rec-manage-info">
          <div>
            <div class="acc-manage-title">매월 ${rule.dayOfMonth}일 - ${rule.memo || rule.category}</div>
            <div class="acc-manage-sub">${acc.name} • ${typeBadge} • ₩${formatNumber(rule.amount)}</div>
          </div>
        </div>
        <button class="tx-delete-btn delete-rec-btn" data-id="${rule.id}" title="고정 규칙 삭제">
          <i data-lucide="trash-2"></i>
        </button>
      `;

      const deleteBtn = item.querySelector('.delete-rec-btn');
      if (deleteBtn) {
        deleteBtn.addEventListener('click', () => {
          deleteRecurringRule(rule.id, onRenderApp);
        });
      }

      recListEl.appendChild(item);
    });
  }
}

export function manualSettleCardBill(cardId, onRenderApp) {
  const card = state.accounts.find(a => a.id === cardId);
  if (!card || !card.linkedBankAccountId) {
    alert('연결된 출금 통장이 없습니다.');
    return;
  }

  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();
  const todayStr = formatDate(new Date());

  const cardBillAmount = getCardBillForMonth(cardId, year, month);
  if (cardBillAmount <= 0) {
    alert('이번 달 결제할 카드 대금이 없습니다.');
    return;
  }

  const linkedBank = state.accounts.find(a => a.id === card.linkedBankAccountId);

  if (confirm(`'${linkedBank.name}' 통장에서 '${card.name}' 카드 대금 ₩${formatNumber(cardBillAmount)}을 정산/출금하시겠습니까?`)) {
    const settleTx = {
      id: `settle_manual_${Date.now()}`,
      date: todayStr,
      accountId: card.linkedBankAccountId,
      type: 'expense',
      amount: cardBillAmount,
      category: '기타',
      payment: '계좌이체',
      memo: `💳 ${card.name} 카드 대금 정산 출금`,
      isSettlement: true
    };

    state.transactions.unshift(settleTx);
    saveTransactions();
    if (onRenderApp) onRenderApp();
    showToast(`₩${formatNumber(cardBillAmount)} 카드 대금이 정산 처리되었습니다!`);
  }
}

export function deleteAccount(accId, onRenderApp) {
  if (state.accounts.length <= 1) {
    alert('최소 1개 이상의 계좌가 등록되어 있어야 합니다.');
    return;
  }

  if (confirm('해당 계좌/카드를 삭제하시겠습니까? 관련된 내역도 함께 영향을 받을 수 있습니다.')) {
    state.accounts = state.accounts.filter(a => a.id !== accId);
    saveAccounts();
    const nextIds = state.selectedAccountIds.filter(id => id !== accId);
    setSelectedAccountIds(nextIds.length === 0 ? ['all'] : nextIds);
    if (onRenderApp) onRenderApp();
    showToast('계좌/카드가 삭제되었습니다.');
  }
}

export function deleteRecurringRule(ruleId, onRenderApp) {
  if (confirm('고정 자동 등록 규칙을 삭제하시겠습니까? (이미 생성된 거래 내역은 유지됩니다)')) {
    state.recurringRules = state.recurringRules.filter(r => r.id !== ruleId);
    saveRecurringRules();
    if (onRenderApp) onRenderApp();
    showToast('고정 자동 등록 규칙이 삭제되었습니다.');
  }
}
