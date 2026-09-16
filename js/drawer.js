/* ==========================================================================
   SIDEBAR DRAWER ENGINE
   ========================================================================== */

import { state, setSelectedAccountIds, setDrawerFilter, saveAccounts } from './state.js';
import { formatNumber, showToast } from './helpers.js';

export function openDrawer() {
  const overlay = document.getElementById('drawer-overlay');
  const drawer = document.getElementById('sidebar-drawer');
  if (overlay) overlay.classList.add('open');
  if (drawer) drawer.classList.add('open');
}

export function closeDrawer() {
  const overlay = document.getElementById('drawer-overlay');
  const drawer = document.getElementById('sidebar-drawer');
  if (overlay) overlay.classList.remove('open');
  if (drawer) drawer.classList.remove('open');
  closeAddTypeMenu();
}

/* ------------------------------------------------------------------
   TYPE SELECTION MENU (계좌/신용카드/체크카드)
   ------------------------------------------------------------------ */
let _typeMenuOpen = false;

function openAddTypeMenu() {
  const menu = document.getElementById('drawer-add-type-menu');
  const label = document.getElementById('drawer-add-label');
  const icon = document.getElementById('drawer-add-icon');
  if (!menu) return;
  _typeMenuOpen = true;
  menu.style.display = 'flex';
  if (label) label.textContent = '닫기';
  if (icon) icon.setAttribute('data-lucide', 'x');
  if (window.lucide) lucide.createIcons();
}

function closeAddTypeMenu() {
  const menu = document.getElementById('drawer-add-type-menu');
  const label = document.getElementById('drawer-add-label');
  const icon = document.getElementById('drawer-add-icon');
  if (!menu) return;
  _typeMenuOpen = false;
  menu.style.display = 'none';
  if (label) label.textContent = '계좌/카드 추가';
  if (icon) icon.setAttribute('data-lucide', 'plus');
  if (window.lucide) lucide.createIcons();
}

/* ------------------------------------------------------------------
   INLINE ACCOUNT ADD MODAL (in-drawer bottom sheet style)
   ------------------------------------------------------------------ */
const BANKS = [
  '신한은행', '카카오뱅크', 'KB국민은행', '현대카드', '삼성카드',
  '토스뱅크', '우리은행', '하나은행', 'NH농협', '현금/기타'
];

const BANK_EMOJI = {
  '신한은행': '🏦', '카카오뱅크': '💛', 'KB국민은행': '💛',
  '현대카드': '💳', '삼성카드': '💳', '토스뱅크': '💙',
  '우리은행': '💙', '하나은행': '💚', 'NH농협': '💚', '현금/기타': '💵'
};

const ACC_COLORS = ['#6366f1','#3b82f6','#10b981','#f59e0b','#ec4899','#8b5cf6','#ef4444','#06b6d4'];

function removeInlineForm() {
  const existing = document.getElementById('drawer-inline-form');
  if (existing) existing.remove();
}

function openInlineForm(type) {
  removeInlineForm();
  closeAddTypeMenu();

  const footer = document.querySelector('.drawer-footer-actions');
  if (!footer) return;

  const form = document.createElement('div');
  form.id = 'drawer-inline-form';
  form.className = 'drawer-inline-form';

  const typeLabel = type === 'bank' ? '계좌 (통장)' : type === 'credit' ? '신용카드' : '체크카드';
  const typeIcon = type === 'bank' ? '🏦' : '💳';

  // --- Build form fields ---
  let paymentDayField = '';
  if (type === 'credit') {
    paymentDayField = `
      <div class="dif-group">
        <label class="dif-label">결제일</label>
        <div class="dif-day-grid" id="dif-day-grid">
          ${[5,10,14,15,20,25,27].map(d => `<button type="button" class="dif-day-btn ${d===25?'active':''}" data-day="${d}">${d}일</button>`).join('')}
        </div>
        <input type="hidden" id="dif-payment-day" value="25">
      </div>
    `;
  }

  let linkedBankField = '';
  if (type === 'debit' || type === 'credit') {
    const bankAccounts = state.accounts.filter(a => a.type === 'bank');
    if (bankAccounts.length > 0) {
      linkedBankField = `
        <div class="dif-group">
          <label class="dif-label">${type === 'debit' ? '연결 통장' : '결제 출금 통장'}</label>
          <select class="dif-select" id="dif-linked-bank">
            <option value="">선택 안 함</option>
            ${bankAccounts.map(a => `<option value="${a.id}">${a.name}</option>`).join('')}
          </select>
        </div>
      `;
    }
  }

  let initialBalanceField = '';
  if (type === 'bank') {
    initialBalanceField = `
      <div class="dif-group">
        <label class="dif-label">초기 잔액 (원, 마이너스 가능)</label>
        <input type="number" class="dif-input" id="dif-balance" value="0" placeholder="예: 1500000 또는 -50000" step="1000">
      </div>
    `;
  }

  form.innerHTML = `
    <div class="dif-header">
      <span class="dif-type-badge">${typeIcon} ${typeLabel} 추가</span>
      <button type="button" class="dif-close-btn" id="dif-close-btn"><i data-lucide="x"></i></button>
    </div>

    <div class="dif-group">
      <label class="dif-label">${type === 'bank' ? '은행 선택' : '카드사 선택'}</label>
      <div class="dif-bank-grid" id="dif-bank-grid">
        ${BANKS.map((b, i) => `<button type="button" class="dif-bank-btn ${i===0?'active':''}" data-bank="${b}">${BANK_EMOJI[b] || '🏦'} ${b}</button>`).join('')}
      </div>
      <input type="hidden" id="dif-bank" value="${BANKS[0]}">
    </div>

    <div class="dif-group">
      <label class="dif-label">별칭 (이름)</label>
      <input type="text" class="dif-input" id="dif-name" placeholder="${type === 'bank' ? '예: 주거래 통장' : type === 'credit' ? '예: 신한 쏠 신용카드' : '예: KB 체크카드'}" maxlength="20">
    </div>

    ${initialBalanceField}
    ${paymentDayField}
    ${linkedBankField}

    <div class="dif-group">
      <label class="dif-label">테마 색상</label>
      <div class="dif-color-row" id="dif-color-row">
        ${ACC_COLORS.map((c, i) => `<button type="button" class="dif-color-chip ${i===0?'active':''}" data-color="${c}" style="background:${c};"></button>`).join('')}
      </div>
      <input type="hidden" id="dif-color" value="${ACC_COLORS[0]}">
    </div>

    <button type="button" class="dif-save-btn" id="dif-save-btn">
      <i data-lucide="check"></i> 저장하기
    </button>
  `;

  // Insert before footer button
  footer.insertBefore(form, footer.firstChild);
  if (window.lucide) lucide.createIcons();

  // Bank grid selection
  form.querySelectorAll('.dif-bank-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      form.querySelectorAll('.dif-bank-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const bankInput = document.getElementById('dif-bank');
      if (bankInput) bankInput.value = btn.dataset.bank;
    });
  });

  // Payment day selection
  if (type === 'credit') {
    form.querySelectorAll('.dif-day-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        form.querySelectorAll('.dif-day-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const dayInput = document.getElementById('dif-payment-day');
        if (dayInput) dayInput.value = btn.dataset.day;
      });
    });
  }

  // Color selection
  form.querySelectorAll('.dif-color-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      form.querySelectorAll('.dif-color-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const colorInput = document.getElementById('dif-color');
      if (colorInput) colorInput.value = chip.dataset.color;
    });
  });

  // Close button
  document.getElementById('dif-close-btn').addEventListener('click', () => {
    removeInlineForm();
  });

  // Save button
  document.getElementById('dif-save-btn').addEventListener('click', () => {
    const name = (document.getElementById('dif-name')?.value || '').trim();
    const bank = document.getElementById('dif-bank')?.value || '';
    const color = document.getElementById('dif-color')?.value || '#6366f1';

    if (!name) {
      const nameInput = document.getElementById('dif-name');
      if (nameInput) { nameInput.style.borderColor = 'var(--expense-color)'; nameInput.focus(); }
      return;
    }

    const newAcc = {
      id: `acc_${Date.now()}`,
      type: type === 'bank' ? 'bank' : 'card',
      cardKind: type === 'bank' ? undefined : type,
      name,
      bank,
      color,
    };

    if (type === 'bank') {
      const bal = parseFloat(document.getElementById('dif-balance')?.value || '0');
      newAcc.initialBalance = isNaN(bal) ? 0 : bal;
      newAcc.accountNumber = '';
    }

    if (type === 'credit') {
      const payDay = parseInt(document.getElementById('dif-payment-day')?.value || '25', 10);
      newAcc.paymentDay = payDay;
      const linked = document.getElementById('dif-linked-bank')?.value;
      if (linked) newAcc.linkedBankAccountId = linked;
    }

    if (type === 'debit') {
      const linked = document.getElementById('dif-linked-bank')?.value;
      if (linked) newAcc.linkedBankAccountId = linked;
    }

    state.accounts.push(newAcc);
    saveAccounts();
    removeInlineForm();

    // Re-render checklist
    if (_renderCallback) {
      renderDrawerAmounts();
      renderDrawerChecklist(_renderCallback);
    }

    showToast(`${typeLabel}이(가) 추가되었습니다.`);
  });

  // Scroll form into view
  setTimeout(() => form.scrollIntoView({ behavior: 'smooth', block: 'nearest' }), 50);
}

/* ------------------------------------------------------------------
   DRAWER AMOUNT DISPLAY (자산 및 지출 금액 표시)
   ------------------------------------------------------------------ */
export function renderDrawerAmounts() {
  const now = state.currentDate || new Date();
  const yr = now.getFullYear();
  const mo = now.getMonth();

  let totalAssets = 0;
  let cashExpense = 0;
  let cardExpense = 0;

  state.accounts.forEach(acc => {
    if (acc.type === 'bank') {
      let bal = Number(acc.initialBalance || 0);
      state.transactions.forEach(t => {
        if (t.accountId !== acc.id) return;
        if (t.type === 'income') bal += Number(t.amount);
        if (t.type === 'expense') bal -= Number(t.amount);
      });
      totalAssets += bal;
    }
  });

  // Current month expenses
  state.transactions.forEach(t => {
    const d = new Date(t.date);
    if (d.getFullYear() !== yr || d.getMonth() !== mo) return;
    if (t.type !== 'expense') return;
    const acc = state.accounts.find(a => a.id === t.accountId);
    const isCard = acc && acc.type === 'card' && acc.cardKind === 'credit';
    if (isCard) {
      cardExpense += Number(t.amount);
    } else {
      cashExpense += Number(t.amount);
    }
  });

  const totalExpense = cashExpense + cardExpense;

  const fmt = (n) => {
    if (Math.abs(n) >= 10000) return (n < 0 ? '-' : '') + Math.round(Math.abs(n) / 10000) + '만';
    return formatNumber(n);
  };

  const el = (id, val, cls) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = val;
    el.className = 'drawer-menu-amount ' + (cls || '');
  };

  el('drawer-amt-all', `₩${fmt(totalAssets)}`, totalAssets >= 0 ? 'amt-positive' : 'amt-negative');
  el('drawer-amt-cash', `-₩${fmt(cashExpense)}`, 'amt-expense');
  el('drawer-amt-card', `-₩${fmt(cardExpense)}`, 'amt-card');
  el('drawer-amt-total', `-₩${fmt(totalExpense)}`, 'amt-expense');
}

/* ------------------------------------------------------------------
   DRAWER CHECKLIST
   ------------------------------------------------------------------ */
let _renderCallback = null;

export function initDrawer(onRenderApp) {
  _renderCallback = onRenderApp;

  const openBtn = document.getElementById('open-drawer-btn');
  const closeBtn = document.getElementById('close-drawer-btn');
  const overlay = document.getElementById('drawer-overlay');
  const addAccBtn = document.getElementById('drawer-add-account-btn');
  const bankBtn = document.getElementById('drawer-add-bank-btn');
  const creditBtn = document.getElementById('drawer-add-credit-btn');
  const debitBtn = document.getElementById('drawer-add-debit-btn');

  if (openBtn) openBtn.addEventListener('click', openDrawer);
  if (closeBtn) closeBtn.addEventListener('click', closeDrawer);
  if (overlay) overlay.addEventListener('click', closeDrawer);

  // Toggle type menu
  if (addAccBtn) {
    addAccBtn.addEventListener('click', () => {
      if (_typeMenuOpen) {
        closeAddTypeMenu();
        removeInlineForm();
      } else {
        openAddTypeMenu();
      }
    });
  }

  if (bankBtn) bankBtn.addEventListener('click', () => openInlineForm('bank'));
  if (creditBtn) creditBtn.addEventListener('click', () => openInlineForm('credit'));
  if (debitBtn) debitBtn.addEventListener('click', () => openInlineForm('debit'));

  // Drawer top menu filters
  document.querySelectorAll('.drawer-menu-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const filter = btn.dataset.filter || 'all';
      setDrawerFilter(filter);
      document.querySelectorAll('.drawer-menu-item').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      if (onRenderApp) onRenderApp();
    });
  });

  renderDrawerAmounts();
  renderDrawerChecklist(onRenderApp);
}

export function renderDrawerChecklist(onRenderApp) {
  _renderCallback = onRenderApp;
  const container = document.getElementById('drawer-account-checklist');
  if (!container) return;
  container.innerHTML = '';

  const isAllActive = state.selectedAccountIds.includes('all') || state.selectedAccountIds.length === 0;

  // Master checkbox
  const masterItem = document.createElement('label');
  masterItem.className = 'drawer-checkbox-item master';
  masterItem.innerHTML = `
    <input type="checkbox" id="chk-acc-all" ${isAllActive ? 'checked' : ''}>
    <span class="chk-box-custom ${isAllActive ? 'checked' : ''}">
      <i data-lucide="check"></i>
    </span>
    <span class="chk-label-text">전체 (모든 계좌)</span>
  `;
  masterItem.querySelector('input').addEventListener('change', (e) => {
    setSelectedAccountIds(e.target.checked ? ['all'] : []);
    if (onRenderApp) onRenderApp();
  });
  container.appendChild(masterItem);

  // Individual accounts with balance / bill amount
  state.accounts.forEach(acc => {
    const isChecked = isAllActive || state.selectedAccountIds.includes(acc.id);
    const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
    const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
    const isBank = acc.type === 'bank';

    const iconBadge = isCredit ? '💳' : (isDebit ? '💳' : '🏦');
    const typeTag = isCredit ? '[신용]' : (isDebit ? '[체크]' : '[통장]');

    // Calculate current balance or month bill
    let amountLabel = '';
    if (isBank) {
      let bal = Number(acc.initialBalance || 0);
      state.transactions.forEach(t => {
        if (t.accountId !== acc.id) return;
        if (t.type === 'income') bal += Number(t.amount);
        if (t.type === 'expense') bal -= Number(t.amount);
      });
      const balStr = formatNumber(Math.abs(bal));
      amountLabel = `<span class="chk-acc-amount ${bal < 0 ? 'neg' : ''}">${bal < 0 ? '-' : ''}₩${balStr}</span>`;
    } else if (isCredit) {
      const now = state.currentDate || new Date();
      let monthBill = 0;
      state.transactions.forEach(t => {
        if (t.accountId !== acc.id || t.type !== 'expense') return;
        const d = new Date(t.date);
        if (d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()) {
          monthBill += Number(t.amount);
        }
      });
      amountLabel = `<span class="chk-acc-amount card-amt">-₩${formatNumber(monthBill)}</span>`;
    }

    const accItem = document.createElement('label');
    accItem.className = 'drawer-checkbox-item';
    accItem.innerHTML = `
      <input type="checkbox" value="${acc.id}" ${isChecked ? 'checked' : ''}>
      <span class="chk-box-custom ${isChecked ? 'checked' : ''}" style="--acc-color: ${acc.color || '#4f46e5'}">
        <i data-lucide="check"></i>
      </span>
      <span class="chk-label-text">${iconBadge} <span class="chk-type-tag">${typeTag}</span> ${acc.name}</span>
      ${amountLabel}
    `;

    accItem.querySelector('input').addEventListener('change', () => {
      const checkedInputs = container.querySelectorAll('input[type="checkbox"]:not(#chk-acc-all):checked');
      const selectedIds = Array.from(checkedInputs).map(inp => inp.value);
      setSelectedAccountIds(selectedIds.length === 0 || selectedIds.length === state.accounts.length ? ['all'] : selectedIds);
      if (onRenderApp) onRenderApp();
    });

    container.appendChild(accItem);
  });

  renderDrawerAmounts();
  if (window.lucide) lucide.createIcons();
}
