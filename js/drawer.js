/* ==========================================================================
   SIDEBAR DRAWER ENGINE
   ========================================================================== */

import { state, setSelectedAccountIds, setDrawerFilter, saveAccounts } from './state.js';
import { formatNumber, showToast, bindLongPress } from './helpers.js';
import { showAccountActionModal } from './modals.js';

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

// Favicon logo helper — uses Google S2 favicon service (works for img src)
const FAVICON = (domain) => `https://www.google.com/s2/favicons?domain=${domain}&sz=32`;

const BANKS = [
  { name: '신한은행',   domain: 'shinhan.com' },
  { name: 'KB국민은행', domain: 'kbstar.com' },
  { name: '우리은행',   domain: 'wooribank.com' },
  { name: '하나은행',   domain: 'kebhana.com' },
  { name: 'NH농협은행', domain: 'nonghyup.com' },
  { name: '기업은행',   domain: 'ibk.co.kr' },
  { name: '토스뱅크',   domain: 'tossbank.com' },
  { name: '카카오뱅크', domain: 'kakaobank.com' },
  { name: '케이뱅크',   domain: 'kbanknow.com' },
  { name: 'SC제일은행', domain: 'standardchartered.co.kr' },
  { name: '씨티은행',   domain: 'citibank.co.kr' },
  { name: '수협은행',   domain: 'suhyup-bank.com' },
  { name: '우체국',     domain: 'epost.go.kr' },
  { name: '산업은행',   domain: 'kdb.co.kr' },
  { name: '새마을금고', domain: 'kfcc.co.kr' },
  { name: '신협',       domain: 'cu.co.kr' },
  { name: '대구은행',   domain: 'dgb.co.kr' },
  { name: '부산은행',   domain: 'busanbank.co.kr' },
  { name: '광주은행',   domain: 'kjbank.com' },
  { name: '전북은행',   domain: 'jbbank.co.kr' },
  { name: '경남은행',   domain: 'knbank.co.kr' },
  { name: '제주은행',   domain: 'jejubank.co.kr' },
  { name: '현금/기타',  domain: '' },
];

const CARD_COMPANIES = [
  { name: '신한카드',     domain: 'shinhancard.com' },
  { name: 'KB국민카드',   domain: 'kbcard.com' },
  { name: '삼성카드',     domain: 'samsungcard.com' },
  { name: '현대카드',     domain: 'hyundaicard.com' },
  { name: '롯데카드',     domain: 'lottecard.co.kr' },
  { name: '하나카드',     domain: 'hanacard.co.kr' },
  { name: '우리카드',     domain: 'wooricard.com' },
  { name: 'NH농협카드',   domain: 'nhcard.com' },
  { name: 'BC카드',       domain: 'bccard.com' },
  { name: '씨티카드',     domain: 'citicard.co.kr' },
  { name: '카카오페이카드', domain: 'kakaopay.com' },
  { name: '토스카드',     domain: 'toss.im' },
  { name: 'IBK기업카드',  domain: 'ibk.co.kr' },
  { name: '수협BC카드',   domain: 'suhyup-bank.com' },
  { name: '우체국카드',   domain: 'epost.go.kr' },
];

// Build bank button HTML with favicon logo image
function bankBtnHtml(item, isActive) {
  const logoImg = item.domain
    ? `<img src="${FAVICON(item.domain)}" alt="" class="dif-bank-logo" onerror="this.style.display='none'">`
    : `<span class="dif-bank-logo-fallback">💵</span>`;
  return `<button type="button" class="dif-bank-btn ${isActive ? 'active' : ''}" data-bank="${item.name}">
    ${logoImg}<span>${item.name}</span>
  </button>`;
}

// 5 default colors
const ACC_COLORS_DEFAULT = ['#6366f1', '#3b82f6', '#10b981', '#ec4899', '#f59e0b'];

function removeInlineForm() {
  const existing = document.getElementById('drawer-inline-form');
  if (existing) existing.remove();
}

// Helper: attach click handler to a color chip
function attachChipClick(chip, form) {
  chip.addEventListener('click', () => {
    form.querySelectorAll('.dif-color-chip').forEach(c => c.classList.remove('active'));
    const addBtn = form.querySelector('.dif-color-add-btn');
    if (addBtn) addBtn.classList.remove('active');
    chip.classList.add('active');
    const colorInput = document.getElementById('dif-color');
    if (colorInput && chip.dataset.color) colorInput.value = chip.dataset.color;
  });
}

// Helper: add a new custom color chip before the + button and keep + for more additions
function addCustomColorChip(color, form, addBtnLabel) {
  const colorRow = document.getElementById('dif-color-row');
  const colorInput = document.getElementById('dif-color');
  if (!colorRow || !colorInput) return;

  // Create the permanent chip
  const newChip = document.createElement('button');
  newChip.type = 'button';
  newChip.className = 'dif-color-chip';
  newChip.dataset.color = color;
  newChip.style.background = color;

  // Deselect all others, select new chip
  form.querySelectorAll('.dif-color-chip').forEach(c => c.classList.remove('active'));
  addBtnLabel.classList.remove('active');
  newChip.classList.add('active');

  colorInput.value = color;
  attachChipClick(newChip, form);

  // Insert before the + label button
  colorRow.insertBefore(newChip, addBtnLabel);

  // Reset the hidden color input so user can pick same color again if wanted
  const hiddenPicker = document.getElementById('dif-custom-color-input');
  if (hiddenPicker) hiddenPicker.value = '#6366f1';

  // Reset + button appearance (it stays as + for new picks)
  addBtnLabel.style.background = '';
  const icon = addBtnLabel.querySelector('.dif-color-add-icon');
  if (icon) { icon.textContent = '+'; icon.style.color = ''; }
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

  const bankList = type === 'credit' ? CARD_COMPANIES : BANKS;
  const firstBank = bankList[0].name;

  let paymentDayField = '';
  if (type === 'credit') {
    paymentDayField = `
      <div class="dif-group">
        <label class="dif-label">결제일 (매월 며칠)</label>
        <div class="dif-day-input-row">
          <input type="number" class="dif-input dif-day-input" id="dif-payment-day"
            value="25" min="1" max="31" placeholder="25">
          <span class="dif-day-unit">일</span>
        </div>
        <span class="dif-day-hint">1~31일 사이 숫자를 직접 입력하세요</span>
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

  // Build bank grid HTML using favicon imgs
  const bankGridHtml = bankList.map((item, i) => bankBtnHtml(item, i === 0)).join('');

  // Build default color chips
  const colorChipsHtml = ACC_COLORS_DEFAULT.map((c, i) =>
    `<button type="button" class="dif-color-chip ${i === 0 ? 'active' : ''}" data-color="${c}" style="background:${c};"></button>`
  ).join('');

  form.innerHTML = `
    <div class="dif-header">
      <span class="dif-type-badge">${typeIcon} ${typeLabel} 추가</span>
      <button type="button" class="dif-close-btn" id="dif-close-btn"><i data-lucide="x"></i></button>
    </div>

    <div class="dif-group">
      <label class="dif-label">${type === 'bank' ? '은행 선택' : '카드사 선택'}</label>
      <div class="dif-bank-grid" id="dif-bank-grid">
        ${bankGridHtml}
      </div>
      <input type="hidden" id="dif-bank" value="${firstBank}">
    </div>

    <div class="dif-group">
      <label class="dif-label">별칭 (이름)</label>
      <input type="text" class="dif-input" id="dif-name"
        placeholder="${type === 'bank' ? '예: 주거래 통장' : type === 'credit' ? '예: 신한 쏠 신용카드' : '예: KB 체크카드'}"
        maxlength="20">
    </div>

    ${initialBalanceField}
    ${paymentDayField}
    ${linkedBankField}

    <div class="dif-group">
      <label class="dif-label">테마 색상</label>
      <div class="dif-color-row" id="dif-color-row">
        ${colorChipsHtml}
        <label class="dif-color-chip dif-color-add-btn" title="색상 추가" id="dif-custom-color-label">
          <span class="dif-color-add-icon">+</span>
          <input type="color" id="dif-custom-color-input" value="#6366f1"
            style="opacity:0;position:absolute;width:0;height:0;">
        </label>
      </div>
      <input type="hidden" id="dif-color" value="${ACC_COLORS_DEFAULT[0]}">
    </div>

    <button type="button" class="dif-save-btn" id="dif-save-btn">
      <i data-lucide="check"></i> 저장하기
    </button>
  `;

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

  // Payment day input validation
  if (type === 'credit') {
    const dayInput = document.getElementById('dif-payment-day');
    if (dayInput) {
      dayInput.addEventListener('blur', () => {
        let v = parseInt(dayInput.value, 10);
        if (isNaN(v) || v < 1) v = 1;
        if (v > 31) v = 31;
        dayInput.value = v;
      });
    }
  }

  // Default color chip click handlers
  form.querySelectorAll('.dif-color-chip').forEach(chip => attachChipClick(chip, form));

  // Custom color picker — adds a new chip each time
  const customColorInput = document.getElementById('dif-custom-color-input');
  const customColorLabel = document.getElementById('dif-custom-color-label');
  if (customColorInput && customColorLabel) {
    customColorInput.addEventListener('change', () => {
      addCustomColorChip(customColorInput.value, form, customColorLabel);
    });
  }


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
  let totalIncome = 0;
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

  // Current month income & expenses
  state.transactions.forEach(t => {
    const d = new Date(t.date);
    if (d.getFullYear() !== yr || d.getMonth() !== mo) return;
    if (t.type === 'income') {
      totalIncome += Number(t.amount);
    } else if (t.type === 'expense') {
      const acc = state.accounts.find(a => a.id === t.accountId);
      const isCard = acc && acc.type === 'card' && acc.cardKind === 'credit';
      if (isCard) {
        cardExpense += Number(t.amount);
      } else {
        cashExpense += Number(t.amount);
      }
    }
  });

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
  el('drawer-amt-income', `+₩${fmt(totalIncome)}`, 'amt-income');
  el('drawer-amt-cash', `-₩${fmt(cashExpense)}`, 'amt-expense');
  el('drawer-amt-card', `-₩${fmt(cardExpense)}`, 'amt-card');
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

    const isLongPress = bindLongPress(accItem, () => {
      showAccountActionModal(acc, onRenderApp);
    });

    accItem.querySelector('input').addEventListener('change', (e) => {
      if (isLongPress()) {
        e.preventDefault();
        return;
      }
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
