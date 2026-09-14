/* ==========================================================================
   SMART BUDGET APP v4.0 - CONFIRMED DEBITS VS NEXT MONTH CARD BILL SEPARATION
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // --- LOCAL STORAGE KEYS ---
  const STORAGE_KEY_TX = 'smart_budget_transactions_v5.0';
  const STORAGE_KEY_ACC = 'smart_budget_accounts_v5.0';
  const STORAGE_KEY_REC = 'smart_budget_recurring_v5.0';

  // --- STATE MANAGEMENT ---
  let currentDate = new Date(); // Active Month / Year view
  let selectedDateStr = formatDate(new Date()); // Active Selected Day ('YYYY-MM-DD')
  let selectedAccountIds = ['all']; // Active account filters: ['all'] or array of account ids
  
  let accounts = [];
  let transactions = [];
  let recurringRules = [];
  let categoryChartInstance = null;

  // --- FILTER HELPER ---
  function isTransactionMatchingSelection(t) {
    if (selectedAccountIds.includes('all') || selectedAccountIds.length === 0) return true;
    if (selectedAccountIds.includes(t.accountId)) return true;
    
    // Debit card linked to a selected bank account
    const txAcc = accounts.find(a => a.id === t.accountId);
    if (txAcc && txAcc.cardKind === 'debit' && txAcc.linkedBankAccountId) {
      if (selectedAccountIds.includes(txAcc.linkedBankAccountId)) return true;
    }
    return false;
  }

  // Master Data Lists
  const BANKS_LIST = [
    { name: '신한은행', icon: '🏦' },
    { name: 'KB국민은행', icon: '💛' },
    { name: '카카오뱅크', icon: '💛' },
    { name: '토스뱅크', icon: '💙' },
    { name: '우리은행', icon: '💙' },
    { name: '하나은행', icon: '💚' },
    { name: 'NH농협', icon: '💚' },
    { name: 'IBK기업은행', icon: '🏦' },
    { name: 'SC제일은행', icon: '🏦' },
    { name: '현금/기타', icon: '💵' }
  ];

  const CARDS_LIST = [
    { name: '신한카드', icon: '💳' },
    { name: 'KB국민카드', icon: '💳' },
    { name: '현대카드', icon: '💳' },
    { name: '삼성카드', icon: '💳' },
    { name: '롯데카드', icon: '💳' },
    { name: 'BC카드', icon: '💳' },
    { name: 'NH농협카드', icon: '💳' },
    { name: '우리카드', icon: '💳' },
    { name: '하나카드', icon: '💳' },
    { name: '카카오페이카드', icon: '💛' },
    { name: '토스카드', icon: '💙' }
  ];

  // Pre-defined Categories
  const CATEGORIES = [
    { name: '식당', emoji: '🍽️', color: '#f43f5e', type: 'expense' },
    { name: '장보기', emoji: '🛒', color: '#fb923c', type: 'expense' },
    { name: '적금/저축', emoji: '💰', color: '#3b82f6', type: 'savings' },
    { name: '카페/디저트', emoji: '☕', color: '#a855f7', type: 'expense' },
    { name: '교통/차량', emoji: '🚌', color: '#06b6d4', type: 'expense' },
    { name: '문화/쇼핑', emoji: '🎬', color: '#ec4899', type: 'expense' },
    { name: '수입/월급', emoji: '💵', color: '#10b981', type: 'income' },
    { name: '기타', emoji: '🎁', color: '#64748b', type: 'expense' }
  ];

  // --- INITIALIZATION ---
  init();

  function init() {
    loadAccounts();
    loadRecurringRules();
    loadTransactions();

    applyRecurringRules();
    checkAutoCardSettlements();

    setupEventListeners();
    updateLiveClock();
    setInterval(updateLiveClock, 60000);

    renderCategoryGrid();
    renderApp();
  }

  // --- LOCAL STORAGE & DATA LOADING ---
  function loadAccounts() {
    const data = localStorage.getItem(STORAGE_KEY_ACC);
    if (data) {
      try {
        accounts = JSON.parse(data);
      } catch (e) {
        console.error('Failed to parse accounts data', e);
        accounts = getSampleAccounts();
        saveAccounts();
      }
    } else {
      accounts = getSampleAccounts();
      saveAccounts();
    }
  }

  function saveAccounts() {
    localStorage.setItem(STORAGE_KEY_ACC, JSON.stringify(accounts));
  }

  function loadRecurringRules() {
    const data = localStorage.getItem(STORAGE_KEY_REC);
    if (data) {
      try {
        recurringRules = JSON.parse(data);
      } catch (e) {
        console.error('Failed to parse recurring rules', e);
        recurringRules = getSampleRecurringRules();
        saveRecurringRules();
      }
    } else {
      recurringRules = getSampleRecurringRules();
      saveRecurringRules();
    }
  }

  function saveRecurringRules() {
    localStorage.setItem(STORAGE_KEY_REC, JSON.stringify(recurringRules));
  }

  function loadTransactions() {
    const data = localStorage.getItem(STORAGE_KEY_TX);
    if (data) {
      try {
        transactions = JSON.parse(data);
      } catch (e) {
        console.error('Failed to parse transactions', e);
        transactions = getSampleTransactions();
        saveTransactions();
      }
    } else {
      transactions = getSampleTransactions();
      saveTransactions();
    }
  }

  function saveTransactions() {
    localStorage.setItem(STORAGE_KEY_TX, JSON.stringify(transactions));
  }

  // --- DEFAULT INITIAL DATA ---
  function getSampleAccounts() {
    return [
      { id: 'acc_main', type: 'bank', name: '주거래 통장', bank: '신한은행', accountNumber: '', initialBalance: 0, color: '#6366f1' }
    ];
  }

  function getSampleRecurringRules() {
    return [];
  }

  function getSampleTransactions() {
    return [];
  }

  // --- RECURRING ENGINE ---
  function applyRecurringRules() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const monthStr = String(month + 1).padStart(2, '0');

    let addedCount = 0;

    recurringRules.forEach(rule => {
      const targetDayStr = String(rule.dayOfMonth).padStart(2, '0');
      const targetDateStr = `${year}-${monthStr}-${targetDayStr}`;

      const exists = transactions.some(t => t.recurringId === rule.id && t.date === targetDateStr);

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

        transactions.push(newTx);
        addedCount++;
      }
    });

    if (addedCount > 0) {
      saveTransactions();
    }
  }

  function checkAutoCardSettlements() {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();
    const day = today.getDate();

    accounts.filter(a => a.type === 'card' && a.cardKind === 'credit' && a.linkedBankAccountId).forEach(card => {
      if (Number(card.paymentDay) === day) {
        const monthStr = String(month + 1).padStart(2, '0');
        const dayStr = String(day).padStart(2, '0');
        const settlementDateStr = `${year}-${monthStr}-${dayStr}`;
        const settlementId = `settle_${card.id}_${year}_${monthStr}`;

        const alreadySettled = transactions.some(t => t.id === settlementId);
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
            transactions.unshift(settleTx);
            saveTransactions();
          }
        }
      }
    });
  }

  function getCardBillForMonth(cardId, year, month) {
    return transactions.filter(t => {
      const d = new Date(t.date);
      return t.accountId === cardId && d.getFullYear() === year && d.getMonth() === month && t.type === 'expense';
    }).reduce((sum, t) => sum + Number(t.amount || 0), 0);
  }

  // --- CORE RENDER FUNCTION ---
  function renderApp() {
    renderAccountTabs();
    renderAccountSelectOptions();
    renderHeaderSummary();
    renderCalendar();
    renderDailyDetail();
    renderStatsView();
    renderSettingsView();

    if (window.lucide) {
      lucide.createIcons();
    }
  }

  // --- ACCOUNT TABS SELECTOR ---
  function renderAccountTabs() {
    const tabsContainer = document.getElementById('account-tabs');
    if (!tabsContainer) return;
    tabsContainer.innerHTML = '';

    const isAllActive = selectedAccountIds.includes('all') || selectedAccountIds.length === 0;

    // 1. "전체 자산" Chip
    const allChip = document.createElement('div');
    allChip.className = `account-tab-chip ${isAllActive ? 'active' : ''}`;
    allChip.innerHTML = `
      <span class="acc-badge-dot" style="background: var(--primary);"></span>
      <span>${isAllActive ? '✓ ' : ''}🌐 전체 자산 (${accounts.length})</span>
    `;
    allChip.addEventListener('click', () => {
      selectedAccountIds = ['all'];
      renderApp();
    });
    tabsContainer.appendChild(allChip);

    // 2. Bank Accounts & Cards Chips
    accounts.forEach(acc => {
      const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
      const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
      const iconBadge = isCredit ? '💳 [신용]' : (isDebit ? '💳 [체크]' : '🏦 [통장]');

      const isSelected = !isAllActive && selectedAccountIds.includes(acc.id);

      const chip = document.createElement('div');
      chip.className = `account-tab-chip ${isSelected ? 'active' : ''}`;
      chip.innerHTML = `
        <span class="acc-badge-dot" style="background: ${acc.color || '#6366f1'};"></span>
        <span>${isSelected ? '✓ ' : ''}${iconBadge} ${acc.name}</span>
      `;

      chip.addEventListener('click', () => {
        if (selectedAccountIds.includes('all')) {
          selectedAccountIds = [acc.id];
        } else {
          if (selectedAccountIds.includes(acc.id)) {
            selectedAccountIds = selectedAccountIds.filter(id => id !== acc.id);
            if (selectedAccountIds.length === 0) {
              selectedAccountIds = ['all'];
            }
          } else {
            selectedAccountIds.push(acc.id);
            if (selectedAccountIds.length === accounts.length) {
              selectedAccountIds = ['all'];
            }
          }
        }
        renderApp();
      });

      tabsContainer.appendChild(chip);
    });
  }

  function renderAccountSelectOptions() {
    const select = document.getElementById('tx-account-select');
    const linkedSelect = document.getElementById('acc-linked-bank');

    if (select) {
      select.innerHTML = '';
      accounts.forEach(acc => {
        const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
        const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
        const badge = isCredit ? '💳 [신용카드]' : (isDebit ? '💳 [체크카드]' : '🏦 [통장]');

        const opt = document.createElement('option');
        opt.value = acc.id;
        opt.textContent = `${badge} ${acc.name} (${acc.bank})`;
        if (selectedAccountIds.length === 1 && selectedAccountIds[0] === acc.id) {
          opt.selected = true;
        }
        select.appendChild(opt);
      });
    }

    if (linkedSelect) {
      linkedSelect.innerHTML = '';
      accounts.filter(a => a.type === 'bank' || !a.type).forEach(bank => {
        const opt = document.createElement('option');
        opt.value = bank.id;
        opt.textContent = `🏦 ${bank.name} (${bank.bank})`;
        linkedSelect.appendChild(opt);
      });
    }
  }

  function updateBankOrCardDropdownOptions(isCardType) {
    const bankSelect = document.getElementById('acc-bank');
    if (!bankSelect) return;

    bankSelect.innerHTML = '';
    const list = isCardType ? CARDS_LIST : BANKS_LIST;

    list.forEach(item => {
      const opt = document.createElement('option');
      opt.value = item.name;
      opt.textContent = `${item.icon} ${item.name}`;
      bankSelect.appendChild(opt);
    });
  }

  // --- HEADER SUMMARY (이번 달 확정 출금액 vs 다음 달 출금 예정액 구분) ---
  function renderHeaderSummary() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    document.getElementById('month-year-text').textContent = `${year}년 ${month + 1}월`;

    // Calculate Previous Month billing period
    const prevMonthObj = new Date(year, month - 1, 1);
    const pYear = prevMonthObj.getFullYear();
    const pMonth = prevMonthObj.getMonth();

    // 1. ALWAYS UPDATE DASHBOARD NET ASSET BANNER (전체 순자산)
    let globalBankInitial = accounts.filter(a => a.type === 'bank' || !a.type).reduce((sum, a) => sum + Number(a.initialBalance || 0), 0);
    let globalBankIncome = 0;
    let globalBankExpense = 0;

    transactions.forEach(t => {
      const txAcc = accounts.find(a => a.id === t.accountId);
      const amt = Number(t.amount);

      if (txAcc && (txAcc.type === 'bank' || !txAcc.type || txAcc.cardKind === 'debit')) {
        if (t.type === 'income') globalBankIncome += amt;
        if (t.type === 'expense') globalBankExpense += amt;
      }
    });

    const globalBankBalance = globalBankInitial + globalBankIncome - globalBankExpense;

    let globalNextMonthBills = 0;
    accounts.filter(a => a.type === 'card' && a.cardKind === 'credit').forEach(card => {
      globalNextMonthBills += getCardBillForMonth(card.id, year, month);
    });

    const globalNetAsset = globalBankBalance - globalNextMonthBills;

    const dashNetEl = document.getElementById('dash-net-assets');
    if (dashNetEl) dashNetEl.textContent = `₩${formatNumber(globalNetAsset)}`;

    // 2. SUMMARY CARDS CALCULATION (선택된 계좌/카드 기반)
    const isAllSelected = selectedAccountIds.includes('all') || selectedAccountIds.length === 0;

    const monthTxs = transactions.filter(t => {
      const d = new Date(t.date);
      const isSameMonth = d.getFullYear() === year && d.getMonth() === month;
      return isSameMonth && isTransactionMatchingSelection(t);
    });

    let totalIncome = 0;
    let cashDebitExpense = 0;

    monthTxs.forEach(t => {
      const amt = Number(t.amount);
      const txAcc = accounts.find(a => a.id === t.accountId);

      if (t.type === 'income') {
        totalIncome += amt;
      } else if (t.type === 'expense') {
        if (!txAcc || txAcc.type !== 'card' || txAcc.cardKind !== 'credit') {
          cashDebitExpense += amt;
        }
      }
    });

    // A. 이번 달 카드 결제액 (전월 사용분 -> 이번 달 결제일에 출금)
    let thisMonthCardBill = 0;
    accounts.filter(a => a.type === 'card' && a.cardKind === 'credit').forEach(card => {
      if (isAllSelected || selectedAccountIds.includes(card.id) || selectedAccountIds.includes(card.linkedBankAccountId)) {
        thisMonthCardBill += getCardBillForMonth(card.id, pYear, pMonth);
      }
    });

    // B. 다음 달 카드 출금 예정액 (당월 사용분 -> 다음 달 결제일에 출금)
    let nextMonthCardBill = 0;
    accounts.filter(a => a.type === 'card' && a.cardKind === 'credit').forEach(card => {
      if (isAllSelected || selectedAccountIds.includes(card.id) || selectedAccountIds.includes(card.linkedBankAccountId)) {
        nextMonthCardBill += getCardBillForMonth(card.id, year, month);
      }
    });

    const incomeEl = document.getElementById('total-income-display');
    const cashExpenseEl = document.getElementById('total-cash-expense-display');
    const thisBillEl = document.getElementById('this-month-bill-display');
    const nextBillEl = document.getElementById('next-month-bill-display');

    const thisBillSubEl = document.getElementById('this-month-bill-sub');
    const nextBillSubEl = document.getElementById('next-month-bill-sub');

    if (incomeEl) incomeEl.textContent = `₩${formatNumber(totalIncome)}`;
    if (cashExpenseEl) cashExpenseEl.textContent = `₩${formatNumber(cashDebitExpense)}`;
    if (thisBillEl) thisBillEl.textContent = `₩${formatNumber(thisMonthCardBill)}`;
    if (nextBillEl) nextBillEl.textContent = `₩${formatNumber(nextMonthCardBill)}`;

    const nextMonthNum = (month + 1) % 12 + 1;
    if (thisBillSubEl) thisBillSubEl.textContent = `${month + 1}월 결제일 출금`;
    if (nextBillSubEl) nextBillSubEl.textContent = `${nextMonthNum}월 결제일 예정`;
  }

  // --- CALENDAR RENDER ENGINE ---
  function renderCalendar() {
    const grid = document.getElementById('calendar-grid');
    grid.innerHTML = '';

    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    const firstDay = new Date(year, month, 1);
    const startingDayOfWeek = firstDay.getDay();
    const totalDaysInMonth = new Date(year, month + 1, 0).getDate();
    const prevMonthDays = new Date(year, month, 0).getDate();
    const todayStr = formatDate(new Date());

    for (let i = startingDayOfWeek - 1; i >= 0; i--) {
      const prevDay = prevMonthDays - i;
      const prevMonthDateStr = formatDate(new Date(year, month - 1, prevDay));
      const cell = createCalendarCell(prevDay, prevMonthDateStr, true);
      grid.appendChild(cell);
    }

    for (let day = 1; day <= totalDaysInMonth; day++) {
      const dateObj = new Date(year, month, day);
      const dateStr = formatDate(dateObj);
      const isToday = dateStr === todayStr;
      const isSelected = dateStr === selectedDateStr;

      const cell = createCalendarCell(day, dateStr, false, isToday, isSelected);
      grid.appendChild(cell);
    }

    const totalCellsSoFar = startingDayOfWeek + totalDaysInMonth;
    const nextDaysNeeded = (totalCellsSoFar > 35 ? 42 : 35) - totalCellsSoFar;

    for (let day = 1; day <= nextDaysNeeded; day++) {
      const nextMonthDateStr = formatDate(new Date(year, month + 1, day));
      const cell = createCalendarCell(day, nextMonthDateStr, true);
      grid.appendChild(cell);
    }
  }

  function createCalendarCell(dayNum, dateStr, isOtherMonth, isToday = false, isSelected = false) {
    const cell = document.createElement('div');
    cell.className = `calendar-cell ${isOtherMonth ? 'other-month' : ''} ${isToday ? 'today' : ''} ${isSelected ? 'selected' : ''}`;
    cell.dataset.date = dateStr;

    const numEl = document.createElement('span');
    numEl.className = 'day-number';
    numEl.textContent = dayNum;
    cell.appendChild(numEl);

    const dateTxs = transactions.filter(t => t.date === dateStr && isTransactionMatchingSelection(t));

    if (dateTxs.length > 0) {
      const badgesContainer = document.createElement('div');
      badgesContainer.className = 'cell-badges';

      let dayExpense = 0;
      let dayIncome = 0;

      dateTxs.forEach(t => {
        if (t.type === 'expense') dayExpense += Number(t.amount);
        if (t.type === 'income' || t.type === 'savings') dayIncome += Number(t.amount);
      });

      if (dayIncome > 0) {
        const incBadge = document.createElement('span');
        incBadge.className = 'badge-income';
        incBadge.textContent = `+${formatCompactNumber(dayIncome)}`;
        badgesContainer.appendChild(incBadge);
      }

      if (dayExpense > 0) {
        const expBadge = document.createElement('span');
        expBadge.className = 'badge-expense';
        expBadge.textContent = `-${formatCompactNumber(dayExpense)}`;
        badgesContainer.appendChild(expBadge);
      }

      cell.appendChild(badgesContainer);
    }

    cell.addEventListener('click', () => {
      selectedDateStr = dateStr;
      const clickedDateObj = new Date(dateStr);
      if (clickedDateObj.getMonth() !== currentDate.getMonth()) {
        currentDate = new Date(clickedDateObj.getFullYear(), clickedDateObj.getMonth(), 1);
        applyRecurringRules();
      }
      renderApp();
    });

    return cell;
  }

  // --- DAILY BREAKDOWN LIST ---
  function renderDailyDetail() {
    const titleEl = document.getElementById('selected-date-title');
    const sumEl = document.getElementById('selected-date-sum');
    const listEl = document.getElementById('transaction-list');

    const [year, month, day] = selectedDateStr.split('-').map(Number);
    const dateObj = new Date(year, month - 1, day);
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    
    let accSubTitle = selectedAccountIds.includes('all') ? '전체 계좌' : 
      (selectedAccountIds.length === 1 ? (accounts.find(a => a.id === selectedAccountIds[0])?.name || '') : `선택 계좌 ${selectedAccountIds.length}개`);
    titleEl.textContent = `${month}월 ${day}일 (${dayNames[dateObj.getDay()]})`;

    const dailyTxs = transactions.filter(t => t.date === selectedDateStr && isTransactionMatchingSelection(t));

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

      const txAcc = accounts.find(a => a.id === tx.accountId) || { name: '미지정 계좌', bank: '', type: 'bank' };
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
      deleteBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        deleteTransaction(tx.id);
      });

      listEl.appendChild(itemEl);
    });
  }

  function deleteTransaction(id) {
    if (confirm('해당 내역을 삭제하시겠습니까?')) {
      transactions = transactions.filter(t => t.id !== id);
      saveTransactions();
      renderApp();
      showToast('항목이 삭제되었습니다.');
    }
  }

  // --- STATS VIEW ---
  function renderStatsView() {
    const periodText = document.getElementById('stats-period-text');
    const breakdownList = document.getElementById('category-breakdown-list');

    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const accName = selectedAccountIds.includes('all') ? '전체 계좌' : 
      (selectedAccountIds.length === 1 ? (accounts.find(a => a.id === selectedAccountIds[0])?.name || '') : `선택 계좌 ${selectedAccountIds.length}개`);
    periodText.textContent = `${year}년 ${month + 1}월 지출 통계 (${accName})`;

    const monthExpenses = transactions.filter(t => {
      const d = new Date(t.date);
      const isSameMonth = d.getFullYear() === year && d.getMonth() === month && t.type === 'expense';
      return isSameMonth && isTransactionMatchingSelection(t);
    });

    const catMap = {};
    let totalExpenseSum = 0;

    monthExpenses.forEach(t => {
      const amt = Number(t.amount);
      catMap[t.category] = (catMap[t.category] || 0) + amt;
      totalExpenseSum += amt;
    });

    const categoriesArray = Object.keys(catMap).map(catName => {
      const categoryObj = CATEGORIES.find(c => c.name === catName) || { emoji: '📌', color: '#64748b' };
      const amount = catMap[catName];
      const percentage = totalExpenseSum > 0 ? Math.round((amount / totalExpenseSum) * 100) : 0;
      return { name: catName, amount, percentage, ...categoryObj };
    }).sort((a, b) => b.amount - a.amount);

    breakdownList.innerHTML = '';

    if (categoriesArray.length === 0) {
      breakdownList.innerHTML = `
        <div class="empty-state">
          <i data-lucide="pie-chart"></i>
          <p>이번 달 지출 내역이 없습니다.</p>
        </div>
      `;
    } else {
      categoriesArray.forEach(cat => {
        const item = document.createElement('div');
        item.className = 'cat-breakdown-item';
        item.innerHTML = `
          <div class="cat-item-top">
            <span class="cat-item-name">
              <span>${cat.emoji}</span> ${cat.name} <small style="color: var(--text-muted)">(${cat.percentage}%)</small>
            </span>
            <span class="cat-item-value" style="color: ${cat.color}">₩${formatNumber(cat.amount)}</span>
          </div>
          <div class="cat-progress-bar">
            <div class="cat-progress-fill" style="width: ${cat.percentage}%; background: ${cat.color};"></div>
          </div>
        `;
        breakdownList.appendChild(item);
      });
    }

    renderChart(categoriesArray);
  }

  function renderChart(categoriesArray) {
    const ctx = document.getElementById('categoryChart').getContext('2d');

    if (categoryChartInstance) {
      categoryChartInstance.destroy();
    }

    if (categoriesArray.length === 0) return;

    const labels = categoriesArray.map(c => `${c.emoji} ${c.name}`);
    const data = categoriesArray.map(c => c.amount);
    const colors = categoriesArray.map(c => c.color);

    categoryChartInstance = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          data: data,
          backgroundColor: colors,
          borderWidth: 2,
          borderColor: 'transparent',
          hoverOffset: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#94a3b8',
              font: { family: "'Outfit', 'Noto Sans KR', sans-serif", size: 11 },
              boxWidth: 12,
              padding: 10
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.raw || 0;
                return ` ₩${formatNumber(val)}`;
              }
            }
          }
        },
        cutout: '70%'
      }
    });
  }

  // --- SETTINGS VIEW ---
  function renderSettingsView() {
    const bankListEl = document.getElementById('bank-account-manage-list');
    const cardListEl = document.getElementById('card-account-manage-list');
    const recListEl = document.getElementById('recurring-manage-list');

    if (!bankListEl || !cardListEl || !recListEl) return;

    bankListEl.innerHTML = '';
    cardListEl.innerHTML = '';

    const bankAccounts = accounts.filter(a => a.type === 'bank' || !a.type);
    const cardAccounts = accounts.filter(a => a.type === 'card');

    if (bankAccounts.length === 0) {
      bankListEl.innerHTML = `<div class="empty-state" style="padding: 12px;"><p>등록된 입출금 통장이 없습니다.</p></div>`;
    } else {
      bankAccounts.forEach(acc => {
        const isSelected = selectedAccountIds.includes('all') || selectedAccountIds.includes(acc.id);
        const activeBadge = isSelected ? `<span class="account-selected-badge">✔ 선택됨</span>` : '';

        let accInc = 0, accExp = 0;
        transactions.forEach(t => {
          const txAcc = accounts.find(a => a.id === t.accountId);
          if (t.accountId === acc.id || (txAcc && txAcc.cardKind === 'debit' && txAcc.linkedBankAccountId === acc.id)) {
            if (t.type === 'income') accInc += Number(t.amount);
            if (t.type === 'expense') accExp += Number(t.amount);
          }
        });
        const currentBalance = Number(acc.initialBalance || 0) + accInc - accExp;

        const item = document.createElement('div');
        item.className = `account-manage-item ${isSelected ? 'active' : ''}`;
        item.innerHTML = `
          <div class="acc-manage-info">
            <span class="acc-color-dot" style="background: ${acc.color || '#6366f1'}"></span>
            <div>
              <div class="acc-manage-title">🏦 ${acc.name} ${activeBadge}</div>
              <div class="acc-manage-sub">${acc.bank} ${acc.accountNumber ? '• ' + acc.accountNumber : ''}</div>
            </div>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span class="acc-manage-balance">₩${formatNumber(currentBalance)}</span>
            <button class="tx-delete-btn delete-acc-btn" data-id="${acc.id}" title="통장 삭제">
              <i data-lucide="trash-2"></i>
            </button>
          </div>
        `;

        item.addEventListener('click', (e) => {
          if (!e.target.closest('.delete-acc-btn')) {
            selectedAccountIds = [acc.id];
            renderApp();
            showToast(`'${acc.name}' 통장이 선택되었습니다.`);
          }
        });

        item.querySelector('.delete-acc-btn').addEventListener('click', (e) => {
          e.stopPropagation();
          deleteAccount(acc.id);
        });

        bankListEl.appendChild(item);
      });
    }

    if (cardAccounts.length === 0) {
      cardListEl.innerHTML = `<div class="empty-state" style="padding: 12px;"><p>등록된 카드가 없습니다.</p></div>`;
    } else {
      cardAccounts.forEach(acc => {
        const isSelected = selectedAccountIds.includes('all') || selectedAccountIds.includes(acc.id);
        const isCredit = acc.cardKind === 'credit';
        const activeBadge = isSelected ? `<span class="account-selected-badge">✔ 선택됨</span>` : '';
        const typeBadge = isCredit ? `<span class="acc-type-badge card">신용카드</span>` : `<span class="acc-type-badge bank" style="background: rgba(6, 182, 212, 0.15); color: #06b6d4;">체크카드</span>`;

        let balanceDisplayStr = '';
        let settleBtnHtml = '';

        const linkedBank = accounts.find(a => a.id === acc.linkedBankAccountId);
        const linkedName = linkedBank ? ` ➔ ${linkedBank.name}` : '';

        if (isCredit) {
          const cardBill = getCardBillForMonth(acc.id, currentDate.getFullYear(), currentDate.getMonth());
          balanceDisplayStr = `예정액 ₩${formatNumber(cardBill)} (${acc.paymentDay || 25}일)`;

          if (cardBill > 0 && linkedBank) {
            settleBtnHtml = `<button class="settle-card-btn" data-card-id="${acc.id}" title="카드값 즉시 정산">💳 정산</button>`;
          }
        } else {
          let debitExp = 0;
          transactions.filter(t => t.accountId === acc.id && t.type === 'expense').forEach(t => debitExp += Number(t.amount));
          balanceDisplayStr = `이번 달 ₩${formatNumber(debitExp)}`;
        }

        const item = document.createElement('div');
        item.className = `account-manage-item ${isSelected ? 'active' : ''}`;
        item.innerHTML = `
          <div class="acc-manage-info">
            <span class="acc-color-dot" style="background: ${acc.color || '#ec4899'}"></span>
            <div>
              <div class="acc-manage-title">💳 ${acc.name} ${typeBadge} ${activeBadge}</div>
              <div class="acc-manage-sub">${acc.bank} ${acc.accountNumber ? '• ' + acc.accountNumber : ''}${linkedName}</div>
            </div>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span class="acc-manage-balance">${balanceDisplayStr}</span>
            ${settleBtnHtml}
            <button class="tx-delete-btn delete-acc-btn" data-id="${acc.id}" title="카드 삭제">
              <i data-lucide="trash-2"></i>
            </button>
          </div>
        `;

        item.addEventListener('click', (e) => {
          if (!e.target.closest('.delete-acc-btn') && !e.target.closest('.settle-card-btn')) {
            selectedAccountIds = [acc.id];
            renderApp();
            showToast(`'${acc.name}' 카드가 선택되었습니다.`);
          }
        });

        item.querySelector('.delete-acc-btn').addEventListener('click', (e) => {
          e.stopPropagation();
          deleteAccount(acc.id);
        });

        const settleBtn = item.querySelector('.settle-card-btn');
        if (settleBtn) {
          settleBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            manualSettleCardBill(acc.id);
          });
        }

        cardListEl.appendChild(item);
      });
    }

    recListEl.innerHTML = '';
    if (recurringRules.length === 0) {
      recListEl.innerHTML = `
        <div class="empty-state" style="padding: 16px 0;">
          <p>등록된 고정 지출/수입 내역이 없습니다.<br>거래 입력 시 '매월 이 날짜에 자동 등록'을 선택해보세요!</p>
        </div>
      `;
    } else {
      recurringRules.forEach(rule => {
        const acc = accounts.find(a => a.id === rule.accountId) || { name: '계좌' };
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

        item.querySelector('.delete-rec-btn').addEventListener('click', () => {
          deleteRecurringRule(rule.id);
        });

        recListEl.appendChild(item);
      });
    }
  }

  function manualSettleCardBill(cardId) {
    const card = accounts.find(a => a.id === cardId);
    if (!card || !card.linkedBankAccountId) {
      alert('연결된 출금 통장이 없습니다.');
      return;
    }

    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const todayStr = formatDate(new Date());

    const cardBillAmount = getCardBillForMonth(cardId, year, month);
    if (cardBillAmount <= 0) {
      alert('이번 달 결제할 카드 대금이 없습니다.');
      return;
    }

    const linkedBank = accounts.find(a => a.id === card.linkedBankAccountId);

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

      transactions.unshift(settleTx);
      saveTransactions();
      renderApp();
      showToast(`₩${formatNumber(cardBillAmount)} 카드 대금이 정산 처리되었습니다!`);
    }
  }

  function deleteAccount(accId) {
    if (accounts.length <= 1) {
      alert('최소 1개 이상의 계좌가 등록되어 있어야 합니다.');
      return;
    }

    if (confirm('해당 계좌/카드를 삭제하시겠습니까? 관련된 내역도 함께 영향을 받을 수 있습니다.')) {
      accounts = accounts.filter(a => a.id !== accId);
      saveAccounts();
      selectedAccountIds = selectedAccountIds.filter(id => id !== accId);
      if (selectedAccountIds.length === 0) selectedAccountIds = ['all'];
      renderApp();
      showToast('계좌/카드가 삭제되었습니다.');
    }
  }

  function deleteRecurringRule(ruleId) {
    if (confirm('고정 자동 등록 규칙을 삭제하시겠습니까? (이미 생성된 거래 내역은 유지됩니다)')) {
      recurringRules = recurringRules.filter(r => r.id !== ruleId);
      saveRecurringRules();
      renderApp();
      showToast('고정 자동 등록 규칙이 삭제되었습니다.');
    }
  }

  function renderCategoryGrid() {
    const grid = document.getElementById('category-grid');
    grid.innerHTML = '';

    CATEGORIES.forEach((cat, idx) => {
      const chip = document.createElement('div');
      chip.className = `category-chip ${idx === 0 ? 'selected' : ''}`;
      chip.dataset.name = cat.name;

      chip.innerHTML = `
        <span class="cat-emoji">${cat.emoji}</span>
        <span class="cat-label">${cat.name}</span>
      `;

      chip.addEventListener('click', () => {
        document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('selected'));
        chip.classList.add('selected');
        document.getElementById('tx-category').value = cat.name;
      });

      grid.appendChild(chip);
    });
  }

  // --- EVENT LISTENERS & MODALS ---
  function setupEventListeners() {
    const accTypeBank = document.getElementById('acc-type-bank');
    const accTypeCard = document.getElementById('acc-type-card');
    const accTypeDebit = document.getElementById('acc-type-debit');
    const linkedGroup = document.getElementById('card-linked-bank-group');
    const paymentDayGroup = document.getElementById('card-payment-day-group');
    const balanceGroup = document.getElementById('acc-balance-group');

    const toggleAccTypeFields = () => {
      if (accTypeCard && accTypeCard.checked) {
        linkedGroup.style.display = 'block';
        paymentDayGroup.style.display = 'block';
        balanceGroup.style.display = 'none';
        updateBankOrCardDropdownOptions(true);
      } else if (accTypeDebit && accTypeDebit.checked) {
        linkedGroup.style.display = 'block';
        paymentDayGroup.style.display = 'none';
        balanceGroup.style.display = 'none';
        updateBankOrCardDropdownOptions(true);
      } else {
        linkedGroup.style.display = 'none';
        paymentDayGroup.style.display = 'none';
        balanceGroup.style.display = 'block';
        updateBankOrCardDropdownOptions(false);
      }
    };

    [accTypeBank, accTypeCard, accTypeDebit].forEach(el => {
      if (el) el.addEventListener('change', toggleAccTypeFields);
    });

    document.getElementById('prev-month-btn').addEventListener('click', () => {
      currentDate.setMonth(currentDate.getMonth() - 1);
      applyRecurringRules();
      renderApp();
    });

    document.getElementById('next-month-btn').addEventListener('click', () => {
      currentDate.setMonth(currentDate.getMonth() + 1);
      applyRecurringRules();
      renderApp();
    });

    document.getElementById('today-btn').addEventListener('click', () => {
      currentDate = new Date();
      selectedDateStr = formatDate(currentDate);
      applyRecurringRules();
      renderApp();
    });

    // Account tabs horizontal scrolling (Mouse drag + Mouse wheel + Arrow buttons)
    const tabsContainer = document.getElementById('account-tabs');
    const scrollLeftBtn = document.getElementById('account-scroll-left');
    const scrollRightBtn = document.getElementById('account-scroll-right');

    if (tabsContainer) {
      // 1. Mouse wheel vertical-to-horizontal conversion
      tabsContainer.addEventListener('wheel', (e) => {
        if (e.deltaY !== 0) {
          e.preventDefault();
          tabsContainer.scrollLeft += e.deltaY;
        }
      }, { passive: false });

      // 2. Mouse click & drag scrolling
      let isDown = false;
      let startX = 0;
      let scrollLeftPos = 0;
      let hasDragged = false;

      tabsContainer.addEventListener('mousedown', (e) => {
        isDown = true;
        hasDragged = false;
        tabsContainer.classList.add('dragging');
        startX = e.pageX - tabsContainer.offsetLeft;
        scrollLeftPos = tabsContainer.scrollLeft;
      });

      tabsContainer.addEventListener('mouseleave', () => {
        isDown = false;
        tabsContainer.classList.remove('dragging');
      });

      tabsContainer.addEventListener('mouseup', () => {
        isDown = false;
        tabsContainer.classList.remove('dragging');
      });

      tabsContainer.addEventListener('mousemove', (e) => {
        if (!isDown) return;
        const x = e.pageX - tabsContainer.offsetLeft;
        const walk = (x - startX) * 1.5;
        if (Math.abs(walk) > 5) {
          hasDragged = true;
        }
        tabsContainer.scrollLeft = scrollLeftPos - walk;
      });

      tabsContainer.addEventListener('click', (e) => {
        if (hasDragged) {
          e.stopPropagation();
          e.preventDefault();
          hasDragged = false;
        }
      }, true);

      // 3. Left/Right Arrow button click navigation
      if (scrollLeftBtn) {
        scrollLeftBtn.addEventListener('click', () => {
          tabsContainer.scrollBy({ left: -160, behavior: 'smooth' });
        });
      }

      if (scrollRightBtn) {
        scrollRightBtn.addEventListener('click', () => {
          tabsContainer.scrollBy({ left: 160, behavior: 'smooth' });
        });
      }
    }

    const tabs = document.querySelectorAll('.nav-tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        const viewId = tab.dataset.view;
        document.querySelectorAll('.app-view').forEach(v => v.classList.remove('active'));
        document.getElementById(`view-${viewId}`).classList.add('active');

        const fab = document.getElementById('fab-add-btn');
        if (viewId === 'calendar') fab.style.display = 'flex';
        else fab.style.display = 'none';
      });
    });

    const txModalOverlay = document.getElementById('tx-modal-overlay');
    const openModalBtn = document.getElementById('open-add-modal-btn');
    const fabAddBtn = document.getElementById('fab-add-btn');
    const closeModalBtn = document.getElementById('close-modal-btn');

    const openTxModal = () => {
      document.getElementById('tx-date').value = selectedDateStr;
      document.getElementById('tx-amount').value = '';
      document.getElementById('tx-memo').value = '';
      document.getElementById('tx-is-recurring').checked = false;
      renderAccountSelectOptions();
      txModalOverlay.classList.add('active');
    };

    const closeTxModal = () => {
      txModalOverlay.classList.remove('active');
    };

    openModalBtn.addEventListener('click', openTxModal);
    fabAddBtn.addEventListener('click', openTxModal);
    closeModalBtn.addEventListener('click', closeTxModal);

    txModalOverlay.addEventListener('click', (e) => {
      if (e.target === txModalOverlay) closeTxModal();
    });

    const accModalOverlay = document.getElementById('acc-modal-overlay');
    const openAccModalBtn = document.getElementById('open-account-modal-btn');
    const settingsAddBankBtn = document.getElementById('settings-add-bank-btn');
    const settingsAddCardBtn = document.getElementById('settings-add-card-btn');
    const closeAccModalBtn = document.getElementById('close-acc-modal-btn');

    const openAccModal = (targetType = 'bank') => {
      document.getElementById('acc-name').value = '';
      document.getElementById('acc-number').value = '';
      document.getElementById('acc-balance').value = '0';

      if (targetType === 'card') {
        document.getElementById('acc-type-card').checked = true;
      } else {
        document.getElementById('acc-type-bank').checked = true;
      }
      
      toggleAccTypeFields();
      renderAccountSelectOptions();
      accModalOverlay.classList.add('active');
    };

    const closeAccModal = () => {
      accModalOverlay.classList.remove('active');
    };

    if (openAccModalBtn) openAccModalBtn.addEventListener('click', () => openAccModal('bank'));
    if (settingsAddBankBtn) settingsAddBankBtn.addEventListener('click', () => openAccModal('bank'));
    if (settingsAddCardBtn) settingsAddCardBtn.addEventListener('click', () => openAccModal('card'));
    if (closeAccModalBtn) closeAccModalBtn.addEventListener('click', closeAccModal);

    accModalOverlay.addEventListener('click', (e) => {
      if (e.target === accModalOverlay) closeAccModal();
    });

    document.querySelectorAll('#acc-color-grid .color-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        document.querySelectorAll('#acc-color-grid .color-chip').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        document.getElementById('acc-color').value = chip.dataset.color;
      });
    });

    document.getElementById('acc-form').addEventListener('submit', (e) => {
      e.preventDefault();

      const typeRadio = document.querySelector('input[name="acc-type"]:checked').value;
      const name = document.getElementById('acc-name').value.trim();
      const bank = document.getElementById('acc-bank').value;
      const accountNumber = document.getElementById('acc-number').value.trim();
      const initialBalance = Number(document.getElementById('acc-balance').value) || 0;
      const linkedBankAccountId = document.getElementById('acc-linked-bank').value;
      const paymentDay = Number(document.getElementById('acc-payment-day').value) || 25;
      const color = document.getElementById('acc-color').value;

      if (!name) {
        alert('명칭을 입력해주세요.');
        return;
      }

      let type = 'bank';
      let cardKind = null;

      if (typeRadio === 'card') {
        type = 'card';
        cardKind = 'credit';
      } else if (typeRadio === 'debit') {
        type = 'card';
        cardKind = 'debit';
      }

      const newAcc = {
        id: `acc_${Date.now()}`,
        type,
        cardKind,
        name,
        bank,
        accountNumber,
        initialBalance: type === 'bank' ? initialBalance : 0,
        linkedBankAccountId: type === 'card' ? linkedBankAccountId : null,
        paymentDay: cardKind === 'credit' ? paymentDay : null,
        color
      };

      accounts.push(newAcc);
      saveAccounts();
      selectedAccountId = newAcc.id;

      closeAccModal();
      renderApp();
      showToast(`새 ${type === 'card' ? '카드' : '통장'} '${name}'이(가) 등록되었습니다!`);
    });

    document.querySelectorAll('.amount-chips .chip-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const amountInput = document.getElementById('tx-amount');
        if (btn.id === 'amount-clear-btn') {
          amountInput.value = '';
          return;
        }
        const addVal = Number(btn.dataset.add);
        const currentVal = Number(amountInput.value) || 0;
        amountInput.value = currentVal + addVal;
      });
    });

    document.querySelectorAll('.pm-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        document.querySelectorAll('.pm-pill').forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        document.getElementById('tx-payment').value = pill.dataset.pm;
      });
    });

    document.getElementById('tx-form').addEventListener('submit', (e) => {
      e.preventDefault();

      const type = document.querySelector('input[name="tx-type"]:checked').value;
      const accountId = document.getElementById('tx-account-select').value;
      const amount = Number(document.getElementById('tx-amount').value);
      const date = document.getElementById('tx-date').value;
      const isRecurring = document.getElementById('tx-is-recurring').checked;
      const category = document.getElementById('tx-category').value;
      const payment = document.getElementById('tx-payment').value;
      const memo = document.getElementById('tx-memo').value.trim();

      if (!amount || amount <= 0) {
        alert('올바른 금액을 입력하세요.');
        return;
      }

      const [y, m, d] = date.split('-').map(Number);
      let recurringId = null;

      if (isRecurring) {
        const newRule = {
          id: `rec_${Date.now()}`,
          accountId,
          dayOfMonth: d,
          type,
          amount,
          category,
          payment,
          memo: memo || `${category} (고정)`
        };
        recurringRules.push(newRule);
        saveRecurringRules();
        recurringId = newRule.id;
      }

      const newTx = {
        id: `tx_${Date.now()}`,
        date,
        accountId,
        type,
        amount,
        category,
        payment,
        memo,
        isRecurring,
        recurringId
      };

      transactions.unshift(newTx);
      saveTransactions();

      selectedDateStr = date;
      const selectedObj = new Date(date);
      currentDate = new Date(selectedObj.getFullYear(), selectedObj.getMonth(), 1);

      closeTxModal();
      renderApp();
      showToast(isRecurring ? '새 거래 내역과 고정 자동 등록 규칙이 추가되었습니다!' : '새로운 가계부 내역이 추가되었습니다!');
    });

    const toggleFrameBtn = document.getElementById('toggle-frame-btn');
    const appViewport = document.getElementById('app-viewport');
    toggleFrameBtn.addEventListener('click', () => {
      appViewport.classList.toggle('frame-mode');
      appViewport.classList.toggle('full-mode');
      toggleFrameBtn.classList.toggle('active');
    });

    const toggleThemeBtn = document.getElementById('toggle-theme-btn');
    const themeIcon = document.getElementById('theme-icon');
    toggleThemeBtn.addEventListener('click', () => {
      document.body.classList.toggle('theme-dark');
      document.body.classList.toggle('theme-light');
      const isLight = document.body.classList.contains('theme-light');
      themeIcon.setAttribute('data-lucide', isLight ? 'sun' : 'moon');
      if (window.lucide) lucide.createIcons();
    });

    // Summary Card Click Detail Listeners
    const incomeCard = document.querySelector('.summary-card.income');
    const cashExpenseCard = document.querySelector('.summary-card.expense-cash');
    const thisCardBillCard = document.querySelector('.summary-card.card-bill-this');
    const nextCardBillCard = document.querySelector('.summary-card.card-bill-next');

    if (incomeCard) incomeCard.addEventListener('click', () => openSummaryDetailModal('income'));
    if (cashExpenseCard) cashExpenseCard.addEventListener('click', () => openSummaryDetailModal('cash-expense'));
    if (thisCardBillCard) thisCardBillCard.addEventListener('click', () => openSummaryDetailModal('this-card-bill'));
    if (nextCardBillCard) nextCardBillCard.addEventListener('click', () => openSummaryDetailModal('next-card-bill'));

    const summaryModalOverlay = document.getElementById('summary-detail-modal-overlay');
    const closeSummaryModalBtn = document.getElementById('close-summary-detail-modal-btn');
    const closeSummaryModalBottomBtn = document.getElementById('close-summary-detail-modal-bottom-btn');

    const closeSummaryDetailModal = () => {
      if (summaryModalOverlay) summaryModalOverlay.classList.remove('active');
    };

    if (closeSummaryModalBtn) closeSummaryModalBtn.addEventListener('click', closeSummaryDetailModal);
    if (closeSummaryModalBottomBtn) closeSummaryModalBottomBtn.addEventListener('click', closeSummaryDetailModal);
    if (summaryModalOverlay) {
      summaryModalOverlay.addEventListener('click', (e) => {
        if (e.target === summaryModalOverlay) closeSummaryDetailModal();
      });
    }

    document.getElementById('reset-sample-data-btn').addEventListener('click', () => {
      if (confirm('모든 계좌 및 거래 데이터를 데모 샘플로 초기화하시겠습니까?')) {
        accounts = getSampleAccounts();
        recurringRules = getSampleRecurringRules();
        transactions = getSampleTransactions();
        saveAccounts();
        saveRecurringRules();
        saveTransactions();
        selectedAccountIds = ['all'];
        renderApp();
        showToast('샘플 데이터가 복원되었습니다.');
      }
    });

    document.getElementById('clear-all-data-btn').addEventListener('click', () => {
      if (confirm('모든 계좌, 고정 규칙 및 가계부 내역을 정말 삭제하시겠습니까?')) {
        accounts = [
          { id: 'acc_main', type: 'bank', name: '기본 통장', bank: '신한은행', accountNumber: '', initialBalance: 0, color: '#6366f1' }
        ];
        transactions = [];
        recurringRules = [];
        saveAccounts();
        saveRecurringRules();
        saveTransactions();
        selectedAccountIds = ['all'];
        renderApp();
        showToast('모든 데이터가 삭제되었습니다.');
      }
    });
  }

  // --- SUMMARY DETAIL MODAL RENDER ENGINE ---
  function openSummaryDetailModal(detailType) {
    const modalOverlay = document.getElementById('summary-detail-modal-overlay');
    const titleEl = document.getElementById('summary-detail-title');
    const emojiEl = document.getElementById('summary-detail-emoji');
    const totalLabelEl = document.getElementById('summary-detail-total-label');
    const totalAmountEl = document.getElementById('summary-detail-total-amount');
    const listEl = document.getElementById('summary-detail-list');

    if (!modalOverlay || !listEl) return;
    listEl.innerHTML = '';

    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    const isAllSelected = selectedAccountIds.includes('all') || selectedAccountIds.length === 0;

    const monthTxs = transactions.filter(t => {
      const d = new Date(t.date);
      const isSameMonth = d.getFullYear() === year && d.getMonth() === month;
      return isSameMonth && isTransactionMatchingSelection(t);
    });

    if (detailType === 'income') {
      emojiEl.textContent = '📥';
      titleEl.textContent = `${month + 1}월 수입 상세 내역`;
      totalLabelEl.textContent = '총 수입 합계';

      const incomeTxs = monthTxs.filter(t => t.type === 'income');
      const totalSum = incomeTxs.reduce((sum, t) => sum + Number(t.amount || 0), 0);
      totalAmountEl.textContent = `+₩${formatNumber(totalSum)}`;

      if (incomeTxs.length === 0) {
        listEl.innerHTML = `<div class="empty-state" style="padding: 24px;"><p>이번 달 등록된 수입 내역이 없습니다.</p></div>`;
      } else {
        incomeTxs.forEach(t => {
          const acc = accounts.find(a => a.id === t.accountId) || { name: '계좌' };
          const categoryObj = CATEGORIES.find(c => c.name === t.category) || { emoji: '💵', color: '#10b981' };

          const item = document.createElement('div');
          item.className = 'tx-item';
          item.innerHTML = `
            <div class="tx-left">
              <div class="tx-icon-pill" style="background: ${categoryObj.color}20; color: ${categoryObj.color}">
                ${categoryObj.emoji}
              </div>
              <div class="tx-info">
                <span class="tx-title">${t.memo || t.category}</span>
                <div class="tx-meta">
                  <span>${t.date}</span> • <span>🏦 ${acc.name}</span> • <span>${t.payment || '입금'}</span>
                </div>
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amount income">+₩${formatNumber(t.amount)}</span>
            </div>
          `;
          listEl.appendChild(item);
        });
      }

    } else if (detailType === 'cash-expense') {
      emojiEl.textContent = '💸';
      titleEl.textContent = `${month + 1}월 현금/체크 지출 상세`;
      totalLabelEl.textContent = '즉시 출금 합계';

      const cashTxs = monthTxs.filter(t => {
        if (t.type !== 'expense') return false;
        const txAcc = accounts.find(a => a.id === t.accountId);
        return !txAcc || txAcc.type !== 'card' || txAcc.cardKind === 'debit';
      });

      const totalSum = cashTxs.reduce((sum, t) => sum + Number(t.amount || 0), 0);
      totalAmountEl.textContent = `-₩${formatNumber(totalSum)}`;

      if (cashTxs.length === 0) {
        listEl.innerHTML = `<div class="empty-state" style="padding: 24px;"><p>이번 달 현금/체크 지출 내역이 없습니다.</p></div>`;
      } else {
        cashTxs.forEach(t => {
          const acc = accounts.find(a => a.id === t.accountId) || { name: '계좌/현금' };
          const categoryObj = CATEGORIES.find(c => c.name === t.category) || { emoji: '🛒', color: '#f43f5e' };
          const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
          const badge = isDebit ? '💳 [체크카드]' : '💵 [현금/계좌]';

          const item = document.createElement('div');
          item.className = 'tx-item';
          item.innerHTML = `
            <div class="tx-left">
              <div class="tx-icon-pill" style="background: ${categoryObj.color}20; color: ${categoryObj.color}">
                ${categoryObj.emoji}
              </div>
              <div class="tx-info">
                <span class="tx-title">${t.memo || t.category}</span>
                <div class="tx-meta">
                  <span>${t.date}</span> • <span>${badge} ${acc.name}</span>
                </div>
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amount expense">-₩${formatNumber(t.amount)}</span>
            </div>
          `;
          listEl.appendChild(item);
        });
      }

    } else if (detailType === 'this-card-bill') {
      emojiEl.textContent = '💳';
      titleEl.textContent = `${month + 1}월 카드 출금 예정액 (전월 사용분)`;
      totalLabelEl.textContent = `${month + 1}월 카드 출금 총액`;

      const prevMonthObj = new Date(year, month - 1, 1);
      const pYear = prevMonthObj.getFullYear();
      const pMonth = prevMonthObj.getMonth();

      const creditCards = accounts.filter(a => a.type === 'card' && a.cardKind === 'credit' && (isAllSelected || selectedAccountIds.includes(a.id) || selectedAccountIds.includes(a.linkedBankAccountId)));

      let grandTotal = 0;

      if (creditCards.length === 0) {
        listEl.innerHTML = `<div class="empty-state" style="padding: 24px;"><p>등록된 신용카드가 없습니다.</p></div>`;
      } else {
        creditCards.forEach(card => {
          const cardTxs = transactions.filter(t => {
            const d = new Date(t.date);
            return t.accountId === card.id && d.getFullYear() === pYear && d.getMonth() === pMonth && t.type === 'expense';
          });

          const cardTotal = cardTxs.reduce((sum, t) => sum + Number(t.amount || 0), 0);
          grandTotal += cardTotal;

          const linkedBank = accounts.find(a => a.id === card.linkedBankAccountId);
          const linkedBankName = linkedBank ? linkedBank.name : '연결 통장 없음';

          const cardGroup = document.createElement('div');
          cardGroup.className = 'summary-detail-card-group';

          let itemsHtml = '';
          if (cardTxs.length === 0) {
            itemsHtml = `<div style="font-size: 0.78rem; color: var(--text-muted); padding: 4px 0;">전월 사용 내역 없음 (출금 예정액 ₩0)</div>`;
          } else {
            cardTxs.forEach(t => {
              const categoryObj = CATEGORIES.find(c => c.name === t.category) || { emoji: '💳', color: '#a855f7' };
              itemsHtml += `
                <div class="tx-item" style="padding: 6px 0; border: none;">
                  <div class="tx-left">
                    <span style="font-size: 0.9rem; margin-right: 6px;">${categoryObj.emoji}</span>
                    <div class="tx-info">
                      <span class="tx-title" style="font-size: 0.82rem;">${t.memo || t.category}</span>
                      <div class="tx-meta" style="font-size: 0.72rem;">${t.date} • ${t.category}</div>
                    </div>
                  </div>
                  <div class="tx-right">
                    <span class="tx-amount expense" style="font-size: 0.85rem;">-₩${formatNumber(t.amount)}</span>
                  </div>
                </div>
              `;
            });
          }

          cardGroup.innerHTML = `
            <div class="summary-detail-card-header">
              <div>
                <div class="summary-detail-card-name">💳 ${card.name}</div>
                <div class="summary-detail-card-sub">${month + 1}월 ${card.paymentDay || 25}일 출금 예정 • 🏦 ${linkedBankName}</div>
              </div>
              <span class="summary-detail-card-amount">₩${formatNumber(cardTotal)}</span>
            </div>
            ${itemsHtml}
          `;

          listEl.appendChild(cardGroup);
        });
      }

      totalAmountEl.textContent = `₩${formatNumber(grandTotal)}`;

    } else if (detailType === 'next-card-bill') {
      emojiEl.textContent = '⏳';
      const nextMonthNum = (month + 1) % 12 + 1;
      titleEl.textContent = `${nextMonthNum}월 출금 예정 카드 내역 (당월 사용분)`;
      totalLabelEl.textContent = `${nextMonthNum}월 청구 예정 총액`;

      const creditCards = accounts.filter(a => a.type === 'card' && a.cardKind === 'credit' && (isAllSelected || selectedAccountIds.includes(a.id) || selectedAccountIds.includes(a.linkedBankAccountId)));

      let grandTotal = 0;

      if (creditCards.length === 0) {
        listEl.innerHTML = `<div class="empty-state" style="padding: 24px;"><p>등록된 신용카드가 없습니다.</p></div>`;
      } else {
        creditCards.forEach(card => {
          const cardTxs = transactions.filter(t => {
            const d = new Date(t.date);
            return t.accountId === card.id && d.getFullYear() === year && d.getMonth() === month && t.type === 'expense';
          });

          const cardTotal = cardTxs.reduce((sum, t) => sum + Number(t.amount || 0), 0);
          grandTotal += cardTotal;

          const linkedBank = accounts.find(a => a.id === card.linkedBankAccountId);
          const linkedBankName = linkedBank ? linkedBank.name : '연결 통장 없음';

          const cardGroup = document.createElement('div');
          cardGroup.className = 'summary-detail-card-group';

          let itemsHtml = '';
          if (cardTxs.length === 0) {
            itemsHtml = `<div style="font-size: 0.78rem; color: var(--text-muted); padding: 4px 0;">이번 달 사용 내역 없음 (예정액 ₩0)</div>`;
          } else {
            cardTxs.forEach(t => {
              const categoryObj = CATEGORIES.find(c => c.name === t.category) || { emoji: '💳', color: '#ec4899' };
              itemsHtml += `
                <div class="tx-item" style="padding: 6px 0; border: none;">
                  <div class="tx-left">
                    <span style="font-size: 0.9rem; margin-right: 6px;">${categoryObj.emoji}</span>
                    <div class="tx-info">
                      <span class="tx-title" style="font-size: 0.82rem;">${t.memo || t.category}</span>
                      <div class="tx-meta" style="font-size: 0.72rem;">${t.date} • ${t.category}</div>
                    </div>
                  </div>
                  <div class="tx-right">
                    <span class="tx-amount expense" style="font-size: 0.85rem;">-₩${formatNumber(t.amount)}</span>
                  </div>
                </div>
              `;
            });
          }

          cardGroup.innerHTML = `
            <div class="summary-detail-card-header">
              <div>
                <div class="summary-detail-card-name">💳 ${card.name}</div>
                <div class="summary-detail-card-sub">${nextMonthNum}월 ${card.paymentDay || 25}일 예정 • 🏦 ${linkedBankName}</div>
              </div>
              <span class="summary-detail-card-amount">₩${formatNumber(cardTotal)}</span>
            </div>
            ${itemsHtml}
          `;

          listEl.appendChild(cardGroup);
        });
      }

      totalAmountEl.textContent = `₩${formatNumber(grandTotal)}`;
    }

    modalOverlay.classList.add('active');
    if (window.lucide) lucide.createIcons();
  }

  // --- HELPERS ---
  function formatDate(d) {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function formatNumber(num) {
    return (num || 0).toLocaleString('ko-KR');
  }

  function formatCompactNumber(num) {
    if (num >= 1000000) return (num / 10000).toFixed(0) + '만';
    if (num >= 10000) return (num / 10000).toFixed(0) + '만';
    if (num >= 1000) return (num / 1000).toFixed(0) + '천';
    return num.toString();
  }

  function updateLiveClock() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const timeEl = document.getElementById('status-time');
    if (timeEl) timeEl.textContent = `${hours}:${minutes}`;
  }

  function showToast(message) {
    const toast = document.getElementById('toast');
    const toastMsg = document.getElementById('toast-message');
    toastMsg.textContent = message;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2800);
  }
});
