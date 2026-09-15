/* ==========================================================================
   MODALS, DROPDOWNS & FORM CONTROLLERS
   ========================================================================== */

import { state, setEditingAccountId, setSelectedDateStr, setCurrentDate, saveActiveViewDate, saveAccounts, saveTransactions, saveRecurringRules, setSelectedAccountIds } from './state.js';
import { BANKS_LIST, CARDS_LIST, CATEGORIES } from './constants.js';
import { parseLocalDateStr, showToast } from './helpers.js';

export function formatFormattedNumberInput(value) {
  if (value === undefined || value === null) return '';
  const str = String(value);
  const isNegative = str.startsWith('-');
  const digits = str.replace(/\D/g, '');
  if (!digits) return isNegative ? '-' : '';
  const formatted = Number(digits).toLocaleString('ko-KR');
  return isNegative ? `-${formatted}` : formatted;
}

export function toggleAccTypeFields() {
  const accTypeCard = document.getElementById('acc-type-card');
  const accTypeDebit = document.getElementById('acc-type-debit');
  const accTypeBank = document.getElementById('acc-type-bank');

  const cardLabel = document.getElementById('acc-type-card-label');
  const debitLabel = document.getElementById('acc-type-debit-label');
  const bankLabel = document.getElementById('acc-type-bank-label');

  const linkedGroup = document.getElementById('card-linked-bank-group');
  const paymentDayGroup = document.getElementById('card-payment-day-group');
  const paymentDayInput = document.getElementById('acc-payment-day');
  const balanceGroup = document.getElementById('acc-balance-group');

  // Update active label styling
  if (cardLabel) cardLabel.classList.toggle('active', !!(accTypeCard && accTypeCard.checked));
  if (debitLabel) debitLabel.classList.toggle('active', !!(accTypeDebit && accTypeDebit.checked));
  if (bankLabel) bankLabel.classList.toggle('active', !!(accTypeBank && accTypeBank.checked));

  if (accTypeCard && accTypeCard.checked) {
    if (linkedGroup) linkedGroup.style.display = 'block';
    if (paymentDayGroup) paymentDayGroup.style.display = 'block';
    if (paymentDayInput) {
      paymentDayInput.disabled = false;
      paymentDayInput.style.opacity = '1';
      paymentDayInput.style.cursor = 'default';
    }
    if (balanceGroup) balanceGroup.style.display = 'none';
    updateBankOrCardDropdownOptions(true);

  } else if (accTypeDebit && accTypeDebit.checked) {
    if (linkedGroup) linkedGroup.style.display = 'block';
    // Keep payment day group visible to prevent height layout shift, but disable the input
    if (paymentDayGroup) paymentDayGroup.style.display = 'block';
    if (paymentDayInput) {
      paymentDayInput.disabled = true;
      paymentDayInput.style.opacity = '0.4';
      paymentDayInput.style.cursor = 'not-allowed';
    }
    if (balanceGroup) balanceGroup.style.display = 'none';
    updateBankOrCardDropdownOptions(true);

  } else {
    if (linkedGroup) linkedGroup.style.display = 'none';
    if (paymentDayGroup) paymentDayGroup.style.display = 'none';
    if (balanceGroup) balanceGroup.style.display = 'block';
    updateBankOrCardDropdownOptions(false);
  }
}

export function updateBankOrCardDropdownOptions(isCardType) {
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

export function renderAccountSelectOptions() {
  const select = document.getElementById('tx-account-select');
  const linkedSelect = document.getElementById('acc-linked-bank');

  if (select) {
    select.innerHTML = '';
    state.accounts.forEach(acc => {
      const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
      const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
      const badge = isCredit ? '💳 [신용카드]' : (isDebit ? '💳 [체크카드]' : '🏦 [통장]');

      const opt = document.createElement('option');
      opt.value = acc.id;
      opt.textContent = `${badge} ${acc.name} (${acc.bank})`;
      if (state.selectedAccountIds.length === 1 && state.selectedAccountIds[0] === acc.id) {
        opt.selected = true;
      }
      select.appendChild(opt);
    });
  }

  if (linkedSelect) {
    linkedSelect.innerHTML = '';
    state.accounts.filter(a => a.type === 'bank' || !a.type).forEach(bank => {
      const opt = document.createElement('option');
      opt.value = bank.id;
      opt.textContent = `🏦 ${bank.name} (${bank.bank})`;
      linkedSelect.appendChild(opt);
    });
  }
}

export function renderCategoryGrid() {
  const grid = document.getElementById('category-grid');
  if (!grid) return;
  grid.innerHTML = '';

  const catInput = document.getElementById('tx-category');
  const selectedCatName = catInput ? catInput.value : (CATEGORIES[0]?.name || '식당');

  CATEGORIES.forEach((cat) => {
    const chip = document.createElement('div');
    const isSelected = cat.name === selectedCatName;
    chip.className = `category-chip ${isSelected ? 'selected' : ''}`;
    chip.dataset.name = cat.name;

    chip.innerHTML = `
      <span class="cat-emoji">${cat.emoji}</span>
      <span class="cat-label">${cat.name}</span>
    `;

    chip.addEventListener('click', () => {
      document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('selected'));
      chip.classList.add('selected');
      if (catInput) catInput.value = cat.name;
    });

    grid.appendChild(chip);
  });

  // Render [+] Add Category Chip
  const addChip = document.createElement('div');
  addChip.className = 'category-chip add-category-chip';
  addChip.style.borderStyle = 'dashed';
  addChip.style.borderColor = 'var(--primary)';
  addChip.innerHTML = `
    <span class="cat-emoji" style="color: var(--primary);">➕</span>
    <span class="cat-label" style="color: var(--primary); font-weight: 700;">추가</span>
  `;

  addChip.addEventListener('click', () => {
    const newName = prompt('추가할 새 카테고리 명칭을 입력하세요 (예: 의료비, 경조사):');
    if (newName && newName.trim()) {
      const cleanName = newName.trim();
      if (!CATEGORIES.some(c => c.name === cleanName)) {
        CATEGORIES.push({ name: cleanName, emoji: '📌', color: '#6366f1', type: 'expense' });
        if (catInput) catInput.value = cleanName;
        renderCategoryGrid();
        showToast(`'${cleanName}' 카테고리가 추가되었습니다!`);
      } else {
        alert('이미 존재하는 카테고리 명칭입니다.');
      }
    }
  });

  grid.appendChild(addChip);
}

export function openAccModal(targetType = 'bank', editAccountObj = null) {
  setEditingAccountId(editAccountObj ? editAccountObj.id : null);

  const accModalOverlay = document.getElementById('acc-modal-overlay');
  const titleEl = document.getElementById('acc-modal-title');
  const saveBtn = document.getElementById('save-acc-btn');

  const accNameInput = document.getElementById('acc-name');
  const accNumberInput = document.getElementById('acc-number');
  const accBalanceInput = document.getElementById('acc-balance');
  const accBankSelect = document.getElementById('acc-bank');
  const accPaymentDayInput = document.getElementById('acc-payment-day');
  const accColorInput = document.getElementById('acc-color');

  const accCardRadio = document.getElementById('acc-type-card');
  const accDebitRadio = document.getElementById('acc-type-debit');
  const accBankRadio = document.getElementById('acc-type-bank');
  const accTypeGroup = document.getElementById('acc-type-group');
  const accTypeLabel = document.getElementById('acc-type-label');
  const accTypeBankLabel = document.getElementById('acc-type-bank-label');

  const isEditing = !!editAccountObj;
  const isCardMode = isEditing ? editAccountObj.type === 'card' : targetType === 'card';

  if (isEditing) {
    if (titleEl) titleEl.textContent = isCardMode ? '카드 정보 수정' : '통장 정보 수정';
    if (saveBtn) saveBtn.innerHTML = '<i data-lucide="check"></i> 수정 완료';

    if (isCardMode) {
      if (editAccountObj.cardKind === 'debit' && accDebitRadio) accDebitRadio.checked = true;
      else if (accCardRadio) accCardRadio.checked = true;
    } else if (accBankRadio) {
      accBankRadio.checked = true;
    }

    if (accNameInput) accNameInput.value = editAccountObj.name || '';
    if (accBankSelect) {
      accBankSelect.value = editAccountObj.bank || '';
      if (!accBankSelect.value && editAccountObj.bank) {
        const opt = document.createElement('option');
        opt.value = editAccountObj.bank;
        opt.textContent = editAccountObj.bank;
        accBankSelect.appendChild(opt);
        accBankSelect.value = editAccountObj.bank;
      }
    }
    if (accNumberInput) accNumberInput.value = editAccountObj.accountNumber || '';
    if (accBalanceInput) accBalanceInput.value = formatFormattedNumberInput(editAccountObj.initialBalance || 0);
    if (accPaymentDayInput && editAccountObj.paymentDay) accPaymentDayInput.value = editAccountObj.paymentDay;

    const linkedSelect = document.getElementById('acc-linked-bank');
    if (linkedSelect && editAccountObj.linkedBankAccountId) linkedSelect.value = editAccountObj.linkedBankAccountId;

    const targetColor = editAccountObj.color || '#6366f1';
    if (accColorInput) accColorInput.value = targetColor;
    document.querySelectorAll('#acc-color-grid .color-chip').forEach(c => {
      c.classList.toggle('active', c.dataset.color === targetColor);
    });

  } else {
    if (titleEl) titleEl.textContent = isCardMode ? '새 카드 등록' : '새 계좌 / 통장 등록';
    if (saveBtn) saveBtn.innerHTML = '<i data-lucide="check"></i> 등록하기';

    if (accNameInput) accNameInput.value = '';
    if (accNumberInput) accNumberInput.value = '';
    if (accBalanceInput) accBalanceInput.value = '0';

    if (isCardMode && accCardRadio) {
      accCardRadio.checked = true;
    } else if (accBankRadio) {
      accBankRadio.checked = true;
    }

    const defaultColor = '#6366f1';
    if (accColorInput) accColorInput.value = defaultColor;
    document.querySelectorAll('#acc-color-grid .color-chip').forEach(c => {
      c.classList.toggle('active', c.dataset.color === defaultColor);
    });
  }

  // Hide or show the Account Type section based on mode
  if (isCardMode) {
    if (accTypeGroup) accTypeGroup.style.display = 'block';
    if (accTypeLabel) accTypeLabel.textContent = '카드 종류';
    if (accTypeBankLabel) accTypeBankLabel.style.display = 'none';
  } else {
    if (accTypeGroup) accTypeGroup.style.display = 'none';
  }

  toggleAccTypeFields();
  renderAccountSelectOptions();

  if (window.lucide) lucide.createIcons();
  if (accModalOverlay) accModalOverlay.classList.add('active');
}

export function closeAccModal() {
  setEditingAccountId(null);
  const accModalOverlay = document.getElementById('acc-modal-overlay');
  if (accModalOverlay) accModalOverlay.classList.remove('active');
}

export function openTxModal() {
  const txModalOverlay = document.getElementById('tx-modal-overlay');
  const txDateInput = document.getElementById('tx-date');
  const txAmountInput = document.getElementById('tx-amount');
  const txMemoInput = document.getElementById('tx-memo');
  const txRecurringInput = document.getElementById('tx-is-recurring');

  if (txDateInput) txDateInput.value = state.selectedDateStr;
  if (txAmountInput) txAmountInput.value = '';
  if (txMemoInput) txMemoInput.value = '';
  if (txRecurringInput) txRecurringInput.checked = false;

  renderAccountSelectOptions();
  if (txModalOverlay) txModalOverlay.classList.add('active');
}

export function closeTxModal() {
  const txModalOverlay = document.getElementById('tx-modal-overlay');
  if (txModalOverlay) txModalOverlay.classList.remove('active');
}

export function setupModalForms(onRenderApp) {
  const accBalanceInput = document.getElementById('acc-balance');
  if (accBalanceInput) {
    accBalanceInput.addEventListener('input', (e) => {
      const formatted = formatFormattedNumberInput(e.target.value);
      e.target.value = formatted;
    });
  }

  const accForm = document.getElementById('acc-form');
  if (accForm) {
    accForm.addEventListener('submit', (e) => {
      e.preventDefault();

      const typeRadioEl = document.querySelector('input[name="acc-type"]:checked');
      const typeRadio = typeRadioEl ? typeRadioEl.value : 'bank';
      const name = (document.getElementById('acc-name')?.value || '').trim();
      const bank = document.getElementById('acc-bank')?.value || '신한은행';
      const accountNumber = (document.getElementById('acc-number')?.value || '').trim();
      const rawBalanceStr = (document.getElementById('acc-balance')?.value || '').replace(/,/g, '');
      const initialBalance = (rawBalanceStr !== '' && !isNaN(Number(rawBalanceStr))) ? Number(rawBalanceStr) : 0;
      const linkedBankAccountId = document.getElementById('acc-linked-bank')?.value || null;
      const paymentDay = Number(document.getElementById('acc-payment-day')?.value) || 25;
      const color = document.getElementById('acc-color')?.value || '#6366f1';

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

      if (state.editingAccountId) {
        const idx = state.accounts.findIndex(a => a.id === state.editingAccountId);
        if (idx !== -1) {
          state.accounts[idx] = {
            ...state.accounts[idx],
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
          saveAccounts();
          showToast(`'${name}' 정보가 수정되었습니다!`);
        }
      } else {
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

        state.accounts.push(newAcc);
        saveAccounts();
        setSelectedAccountIds([newAcc.id]);
        showToast(`새 ${type === 'card' ? '카드' : '통장'} '${name}'이(가) 등록되었습니다!`);
      }

      closeAccModal();
      if (onRenderApp) onRenderApp();
    });
  }

  const txForm = document.getElementById('tx-form');
  if (txForm) {
    txForm.addEventListener('submit', (e) => {
      e.preventDefault();

      const typeRadioEl = document.querySelector('input[name="tx-type"]:checked');
      const type = typeRadioEl ? typeRadioEl.value : 'expense';
      const accountId = document.getElementById('tx-account-select')?.value;
      const amount = Number(document.getElementById('tx-amount')?.value);
      const date = document.getElementById('tx-date')?.value;
      const category = document.getElementById('tx-category')?.value || '식당';
      
      // Auto-derive payment method from selected account
      const selectedAcc = state.accounts.find(a => a.id === accountId);
      let derivedPayment = '현금';
      if (selectedAcc) {
        if (selectedAcc.type === 'card') {
          derivedPayment = selectedAcc.cardKind === 'debit' ? '체크카드' : '신용카드';
        } else if (selectedAcc.type === 'bank') {
          derivedPayment = '계좌이체';
        }
      }
      const payment = derivedPayment;
      const memo = (document.getElementById('tx-memo')?.value || '').trim();

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
        state.recurringRules.push(newRule);
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

      state.transactions.unshift(newTx);
      saveTransactions();

      setSelectedDateStr(date);
      const selectedObj = parseLocalDateStr(date);
      setCurrentDate(new Date(selectedObj.getFullYear(), selectedObj.getMonth(), 1));
      saveActiveViewDate();

      closeTxModal();
      if (onRenderApp) onRenderApp();
      showToast(isRecurring ? '새 거래 내역과 고정 자동 등록 규칙이 추가되었습니다!' : '새로운 가계부 내역이 추가되었습니다!');
    });
  }
}
