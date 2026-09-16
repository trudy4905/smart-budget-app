import { state, isTransactionMatchingSelection, getCardBillForMonth, setSelectedAccountIds, setCurrentDate, setSelectedDateStr, saveActiveViewDate, applyRecurringRules } from './state.js';
import { formatNumber, parseLocalDateStr, formatDate } from './helpers.js';

export function updateHeaderVisibilityForView(viewId) {
  const appHeader = document.querySelector('.app-header');
  if (!appHeader) return;
  if (viewId === 'settings') {
    appHeader.style.display = 'none';
  } else {
    appHeader.style.display = 'block';
  }
}

/* ============================================================
   MONTH CAROUSEL — includes past (2 years back) + future (18 months)
   ============================================================ */
export function renderMonthCarousel(onRenderApp) {
  const container = document.getElementById('month-carousel');
  if (!container) return;
  container.innerHTML = '';

  const activeYr = state.currentDate.getFullYear();
  const activeMo = state.currentDate.getMonth();

  const now = new Date();
  // Start 24 months before today
  const startDate = new Date(now.getFullYear(), now.getMonth() - 24, 1);
  // End 18 months after today
  const endDate = new Date(now.getFullYear(), now.getMonth() + 18, 1);

  let lastYr = null;
  let activePillRef = null;

  const cur = new Date(startDate);
  while (cur <= endDate) {
    const yr = cur.getFullYear();
    const mo = cur.getMonth();

    // Year label separator
    if (lastYr !== null && yr !== lastYr) {
      const yrBadge = document.createElement('span');
      yrBadge.className = 'month-carousel-year-text';
      yrBadge.textContent = `${yr}`;
      container.appendChild(yrBadge);
    }
    lastYr = yr;

    const isSelected = yr === activeYr && mo === activeMo;
    const pill = document.createElement('button');
    pill.className = `month-pill ${isSelected ? 'active' : ''}`;
    pill.textContent = `${mo + 1}월`;
    pill.dataset.yr = yr;
    pill.dataset.mo = mo;

    if (isSelected) activePillRef = pill;

    pill.addEventListener('click', () => {
      setCurrentDate(new Date(yr, mo, 1));
      setSelectedDateStr(formatDate(new Date(yr, mo, 1)));
      saveActiveViewDate();
      applyRecurringRules();
      if (onRenderApp) onRenderApp();
    });

    container.appendChild(pill);
    cur.setMonth(cur.getMonth() + 1);
  }

  // Scroll active pill into view (instant, no animation to avoid jank on re-render)
  if (activePillRef) {
    requestAnimationFrame(() => {
      const pillLeft = activePillRef.offsetLeft;
      const pillWidth = activePillRef.offsetWidth;
      const containerWidth = container.offsetWidth;
      container.scrollLeft = pillLeft - containerWidth / 2 + pillWidth / 2;
    });
  }
}

/* ============================================================
   YEAR / MONTH PICKER POPUP WIDGET
   ============================================================ */
let _pickerOnRenderApp = null;

function createMonthPickerPopup() {
  // Remove existing if any
  const existing = document.getElementById('month-picker-popup');
  if (existing) existing.remove();

  const popup = document.createElement('div');
  popup.id = 'month-picker-popup';
  popup.className = 'month-picker-popup';

  const activeYr = state.currentDate.getFullYear();
  const activeMo = state.currentDate.getMonth();

  // Year navigation header
  let displayYear = activeYr;

  function buildPopupContent() {
    popup.innerHTML = '';

    // Year navigation row
    const yearNav = document.createElement('div');
    yearNav.className = 'mpp-year-nav';

    const prevYrBtn = document.createElement('button');
    prevYrBtn.className = 'mpp-yr-arrow';
    prevYrBtn.innerHTML = '‹';
    prevYrBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      displayYear--;
      buildPopupContent();
    });

    const yearLabel = document.createElement('span');
    yearLabel.className = 'mpp-year-label';
    yearLabel.textContent = `${displayYear}년`;
    // Allow tapping the year to type it directly
    yearLabel.contentEditable = true;
    yearLabel.spellcheck = false;
    yearLabel.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        const parsed = parseInt(yearLabel.textContent.replace(/[^0-9]/g, ''), 10);
        if (!isNaN(parsed) && parsed >= 2000 && parsed <= 2100) {
          displayYear = parsed;
          buildPopupContent();
        }
      }
    });

    const nextYrBtn = document.createElement('button');
    nextYrBtn.className = 'mpp-yr-arrow';
    nextYrBtn.innerHTML = '›';
    nextYrBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      displayYear++;
      buildPopupContent();
    });

    yearNav.appendChild(prevYrBtn);
    yearNav.appendChild(yearLabel);
    yearNav.appendChild(nextYrBtn);

    // Month grid (4 x 3)
    const monthGrid = document.createElement('div');
    monthGrid.className = 'mpp-month-grid';

    const MONTHS_KR = ['1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'];
    MONTHS_KR.forEach((label, idx) => {
      const btn = document.createElement('button');
      btn.className = 'mpp-month-btn';
      btn.textContent = label;

      const isActive = displayYear === activeYr && idx === activeMo;
      const isCurrentMonth = displayYear === new Date().getFullYear() && idx === new Date().getMonth();

      if (isActive) btn.classList.add('active');
      if (isCurrentMonth && !isActive) btn.classList.add('today');

      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        setCurrentDate(new Date(displayYear, idx, 1));
        setSelectedDateStr(formatDate(new Date(displayYear, idx, 1)));
        saveActiveViewDate();
        applyRecurringRules();
        closeMonthPickerPopup();
        if (_pickerOnRenderApp) _pickerOnRenderApp();
      });

      monthGrid.appendChild(btn);
    });

    popup.appendChild(yearNav);
    popup.appendChild(monthGrid);
  }

  buildPopupContent();
  return popup;
}

function closeMonthPickerPopup() {
  const popup = document.getElementById('month-picker-popup');
  if (popup) {
    popup.classList.add('closing');
    setTimeout(() => popup.remove(), 160);
  }
  document.removeEventListener('click', _outsidePickerHandler);
}

function _outsidePickerHandler(e) {
  const popup = document.getElementById('month-picker-popup');
  const btn = document.getElementById('month-picker-btn');
  if (popup && !popup.contains(e.target) && btn && !btn.contains(e.target)) {
    closeMonthPickerPopup();
  }
}

export function initMonthPickerBtn(onRenderApp) {
  _pickerOnRenderApp = onRenderApp;
  const btn = document.getElementById('month-picker-btn');
  if (!btn) return;

  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const existing = document.getElementById('month-picker-popup');
    if (existing) {
      closeMonthPickerPopup();
      return;
    }

    const popup = createMonthPickerPopup();

    // Position below the button
    const header = document.querySelector('.app-header');
    if (header) {
      header.style.position = 'relative';
      header.appendChild(popup);
    } else {
      document.body.appendChild(popup);
    }

    // Trigger open animation
    requestAnimationFrame(() => popup.classList.add('open'));

    setTimeout(() => {
      document.addEventListener('click', _outsidePickerHandler);
    }, 0);
  });
}

/* ============================================================
   ACCOUNT TABS (legacy, kept for compatibility)
   ============================================================ */
export function renderAccountTabs(onRenderApp) {
  const tabsContainer = document.getElementById('account-tabs');
  if (!tabsContainer) return;
  tabsContainer.innerHTML = '';

  const isAllActive = state.selectedAccountIds.includes('all') || state.selectedAccountIds.length === 0;

  const allChip = document.createElement('div');
  allChip.className = `account-tab-chip ${isAllActive ? 'active' : ''}`;
  allChip.innerHTML = `
    <span class="acc-badge-dot" style="background: var(--primary);"></span>
    <span>${isAllActive ? '✓ ' : ''}🌐 전체 자산 (${state.accounts.length})</span>
  `;
  allChip.addEventListener('click', () => {
    setSelectedAccountIds(['all']);
    if (onRenderApp) onRenderApp();
  });
  tabsContainer.appendChild(allChip);

  state.accounts.forEach(acc => {
    const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
    const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
    const iconBadge = isCredit ? '💳 [신용]' : (isDebit ? '💳 [체크]' : '🏦 [통장]');
    const isSelected = !isAllActive && state.selectedAccountIds.includes(acc.id);

    const chip = document.createElement('div');
    chip.className = `account-tab-chip ${isSelected ? 'active' : ''}`;
    chip.innerHTML = `
      <span class="acc-badge-dot" style="background: ${acc.color || '#6366f1'};"></span>
      <span>${isSelected ? '✓ ' : ''}${iconBadge} ${acc.name}</span>
    `;

    chip.addEventListener('click', () => {
      if (state.selectedAccountIds.includes('all')) {
        setSelectedAccountIds([acc.id]);
      } else {
        if (state.selectedAccountIds.includes(acc.id)) {
          const nextIds = state.selectedAccountIds.filter(id => id !== acc.id);
          setSelectedAccountIds(nextIds.length === 0 ? ['all'] : nextIds);
        } else {
          const nextIds = [...state.selectedAccountIds, acc.id];
          setSelectedAccountIds(nextIds.length === state.accounts.length ? ['all'] : nextIds);
        }
      }
      if (onRenderApp) onRenderApp();
    });

    tabsContainer.appendChild(chip);
  });
}

/* ============================================================
   HEADER SUMMARY
   ============================================================ */
export function renderHeaderSummary(onRenderApp) {
  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();

  const monthTextEl = document.getElementById('month-year-text');
  if (monthTextEl) monthTextEl.textContent = `${year}년 ${month + 1}월`;

  const todayNumEl = document.getElementById('today-date-num');
  if (todayNumEl) todayNumEl.textContent = new Date().getDate();

  renderMonthCarousel(onRenderApp);

  // Dashboard net assets (optional, safe if elements missing)
  let globalBankInitial = state.accounts.filter(a => a.type === 'bank' || !a.type).reduce((sum, a) => sum + Number(a.initialBalance || 0), 0);
  let globalBankIncome = 0;
  let globalBankExpense = 0;

  state.transactions.forEach(t => {
    const txAcc = state.accounts.find(a => a.id === t.accountId);
    const amt = Number(t.amount);
    if (txAcc && (txAcc.type === 'bank' || !txAcc.type || txAcc.cardKind === 'debit')) {
      if (t.type === 'income') globalBankIncome += amt;
      if (t.type === 'expense') globalBankExpense += amt;
    }
  });

  const globalBankBalance = globalBankInitial + globalBankIncome - globalBankExpense;

  let globalNextMonthBills = 0;
  state.accounts.filter(a => a.type === 'card' && a.cardKind === 'credit').forEach(card => {
    globalNextMonthBills += getCardBillForMonth(card.id, year, month);
  });

  const globalNetAsset = globalBankBalance - globalNextMonthBills;
  const dashNetEl = document.getElementById('dash-net-assets');
  if (dashNetEl) dashNetEl.textContent = `₩${formatNumber(globalNetAsset)}`;

  // Summary card calculations
  const monthTxs = state.transactions.filter(t => {
    const d = parseLocalDateStr(t.date);
    const isSameMonth = d.getFullYear() === year && d.getMonth() === month;
    return isSameMonth && isTransactionMatchingSelection(t);
  });

  let totalIncome = 0;
  let cashDebitExpense = 0;
  let creditCardExpense = 0;

  monthTxs.forEach(t => {
    const amt = Number(t.amount);
    const txAcc = state.accounts.find(a => a.id === t.accountId);
    if (t.type === 'income') {
      totalIncome += amt;
    } else if (t.type === 'expense') {
      if (txAcc && txAcc.type === 'card' && txAcc.cardKind === 'credit') {
        creditCardExpense += amt;
      } else {
        cashDebitExpense += amt;
      }
    }
  });

  const totalExpense = cashDebitExpense + creditCardExpense;

  const incomeEl = document.getElementById('total-income-display');
  const cashExpenseEl = document.getElementById('total-cash-expense-display');
  const thisBillEl = document.getElementById('this-month-bill-display');
  const nextBillEl = document.getElementById('next-month-bill-display');
  const thisBillSubEl = document.getElementById('this-month-bill-sub');
  const nextBillSubEl = document.getElementById('next-month-bill-sub');

  if (incomeEl) incomeEl.textContent = `₩${formatNumber(totalIncome)}`;
  if (cashExpenseEl) cashExpenseEl.textContent = `₩${formatNumber(cashDebitExpense)}`;
  if (thisBillEl) thisBillEl.textContent = `₩${formatNumber(creditCardExpense)}`;
  if (nextBillEl) nextBillEl.textContent = `₩${formatNumber(totalExpense)}`;

  const creditCardAccs = state.accounts.filter(a => a.type === 'card' && (a.cardKind === 'credit' || !a.cardKind));
  const uniquePaymentDays = [...new Set(creditCardAccs.map(a => a.paymentDay || 25))];

  let paymentTextTag = '(다음달 25일 결제)';
  if (creditCardAccs.length <= 1 || uniquePaymentDays.length === 1) {
    const pDay = uniquePaymentDays[0] || 25;
    paymentTextTag = `(다음달 ${pDay}일 결제)`;
  } else {
    paymentTextTag = `(다음달 카드별 결제)`;
  }

  const thisBillLabelEl = document.getElementById('this-month-bill-label');
  if (thisBillLabelEl) {
    thisBillLabelEl.innerHTML = `<i data-lucide="credit-card"></i> 이번 달 카드 지출 <span style="font-size: 0.65rem; opacity: 0.9; font-weight: 500;">${paymentTextTag}</span>`;
  }

  if (thisBillSubEl) thisBillSubEl.textContent = `${month + 1}월 신용카드 사용액`;
  if (nextBillSubEl) nextBillSubEl.textContent = `현금/체크 + 카드 합계`;
  if (window.lucide) lucide.createIcons();
}
