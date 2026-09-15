/* ==========================================================================
   MODALS, DROPDOWNS & FORM CONTROLLERS
   ========================================================================== */

import { state, setEditingAccountId, setSelectedDateStr, setCurrentDate, saveActiveViewDate, saveAccounts, saveTransactions, saveRecurringRules, setSelectedAccountIds } from './state.js';
import { BANKS_LIST, CARDS_LIST, CATEGORIES, EXPENSE_CATEGORIES, INCOME_CATEGORIES } from './constants.js';
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

export function renderAccountSelectOptions(txType = 'expense') {
  const select = document.getElementById('tx-account-select');
  const linkedSelect = document.getElementById('acc-linked-bank');

  if (select) {
    select.innerHTML = '';
    const filteredAccounts = txType === 'income'
      ? state.accounts.filter(a => a.type === 'bank' || !a.type)
      : state.accounts;

    filteredAccounts.forEach(acc => {
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

export function handleCategoryLongPress(cat, txType) {
  openCategoryActionModal(cat, txType);
}

export function openCategoryActionModal(cat, txType) {
  const overlay = document.getElementById('cat-action-modal-overlay');
  const titleEl = document.getElementById('cat-action-modal-title');
  const bodyEl = document.getElementById('cat-action-modal-body');
  const closeBtn = document.getElementById('close-cat-action-modal-btn');

  if (!overlay || !bodyEl) return;

  const targetList = txType === 'income' ? INCOME_CATEGORIES : EXPENSE_CATEGORIES;

  const closeModal = () => {
    overlay.classList.remove('active');
  };

  if (closeBtn) closeBtn.onclick = closeModal;

  // View 1: Main Choice (수정 / 삭제 / 취소 버튼)
  const renderMainChoice = () => {
    if (titleEl) titleEl.textContent = `${cat.emoji} [${cat.name}] 카테고리 관리`;

    bodyEl.innerHTML = `
      <p style="font-size: 0.82rem; color: var(--text-muted); margin-bottom: 14px;">원하시는 작업을 버튼으로 선택해 주세요.</p>
      <button class="action-choice-btn" id="cat-btn-edit">
        <i data-lucide="pencil"></i> ✏️ 카테고리 이름 수정
      </button>
      <button class="action-choice-btn danger" id="cat-btn-delete">
        <i data-lucide="trash-2"></i> 🗑️ 카테고리 삭제
      </button>
      <button class="btn-secondary" id="cat-btn-cancel" style="width: 100%; margin-top: 6px;">
        취소
      </button>
    `;

    document.getElementById('cat-btn-edit')?.addEventListener('click', () => renderEditView());
    document.getElementById('cat-btn-delete')?.addEventListener('click', () => renderDeleteView());
    document.getElementById('cat-btn-cancel')?.addEventListener('click', closeModal);
    if (window.lucide) lucide.createIcons();
  };

  // View 2A: Edit Category Name
  const renderEditView = () => {
    if (titleEl) titleEl.textContent = `✏️ '${cat.name}' 이름 수정`;

    bodyEl.innerHTML = `
      <div class="form-group">
        <label for="cat-edit-input">새 카테고리 명칭</label>
        <input type="text" id="cat-edit-input" class="form-input" value="${cat.name}" placeholder="새 이름 입력" autocomplete="off">
        <p style="font-size: 0.78rem; color: var(--text-muted); margin-top: 8px;">
          ※ 변경 시 기존에 이 카테고리로 등록된 모든 가계부 내역도 일괄 변경됩니다.
        </p>
      </div>
      <div style="display: flex; gap: 8px; margin-top: 16px;">
        <button class="submit-btn" id="cat-edit-save-btn">수정 완료</button>
        <button class="btn-secondary" id="cat-edit-cancel-btn">취소</button>
      </div>
    `;

    const editInput = document.getElementById('cat-edit-input');
    if (editInput) {
      editInput.focus();
      editInput.select();
    }

    document.getElementById('cat-edit-save-btn')?.addEventListener('click', () => {
      const newName = (document.getElementById('cat-edit-input')?.value || '').trim();
      if (!newName) {
        alert('카테고리 이름을 입력해주세요.');
        return;
      }
      if (newName !== cat.name && targetList.some(c => c.name === newName)) {
        alert(`이미 존재하는 카테고리 이름입니다: '${newName}'`);
        return;
      }

      if (newName !== cat.name) {
        const oldName = cat.name;
        cat.name = newName;

        let txCount = 0;
        state.transactions.forEach(t => {
          if (t.category === oldName) {
            t.category = newName;
            txCount++;
          }
        });
        if (txCount > 0) saveTransactions();

        let recCount = 0;
        state.recurringRules.forEach(r => {
          if (r.category === oldName) {
            r.category = newName;
            recCount++;
          }
        });
        if (recCount > 0) saveRecurringRules();

        const catInput = document.getElementById('tx-category');
        if (catInput && catInput.value === oldName) {
          catInput.value = newName;
        }

        renderCategoryGrid(txType);
        showToast(`'${oldName}' ➔ '${newName}' (관련 내역 ${txCount}개 일괄 변경 완료)`);
      }
      closeModal();
    });

    document.getElementById('cat-edit-cancel-btn')?.addEventListener('click', closeModal);
  };

  // View 2B: Delete Category Selection (ALWAYS shows transfer / re-assignment options)
  const renderDeleteView = () => {
    if (targetList.length <= 1) {
      alert('최소 1개 이상의 카테고리는 유지되어야 합니다.');
      return;
    }

    const affectedTxs = state.transactions.filter(t => t.category === cat.name);
    const countText = affectedTxs.length > 0 ? ` (관련 내역 ${affectedTxs.length}개)` : '';

    if (titleEl) titleEl.textContent = `🗑️ '${cat.name}' 삭제 & 내역 이관`;

    bodyEl.innerHTML = `
      <p style="font-size: 0.86rem; color: var(--text-muted); margin-bottom: 14px; line-height: 1.4;">
        '${cat.name}' 카테고리를 삭제합니다${countText}.<br>이관받을 카테고리를 아래 방법으로 선택해 주세요.
      </p>
      <button class="action-choice-btn" id="cat-reassign-existing-btn">
        📋 기존 카테고리 목록에서 선택하여 이관
      </button>
      <button class="action-choice-btn" id="cat-reassign-new-btn">
        ✨ 새 카테고리 직접 생성 후 이관
      </button>
      <button class="btn-secondary" id="cat-del-cancel-btn" style="width: 100%; margin-top: 6px;">취소</button>
    `;

    document.getElementById('cat-reassign-existing-btn')?.addEventListener('click', () => renderReassignExistingView());
    document.getElementById('cat-reassign-new-btn')?.addEventListener('click', () => renderReassignNewView());
    document.getElementById('cat-del-cancel-btn')?.addEventListener('click', closeModal);
  };

  // View 2B-1: Reassign to Existing Category
  const renderReassignExistingView = () => {
    const remainingCats = targetList.filter(c => c.name !== cat.name);
    if (titleEl) titleEl.textContent = `📋 기존 카테고리로 이관`;

    bodyEl.innerHTML = `
      <div class="form-group">
        <label for="cat-reassign-select">이관받을 기존 카테고리 선택</label>
        <select id="cat-reassign-select" class="form-select">
          ${remainingCats.map(c => `<option value="${c.name}">${c.emoji} ${c.name}</option>`).join('')}
        </select>
      </div>
      <div style="display: flex; gap: 8px; margin-top: 16px;">
        <button class="submit-btn" id="cat-reassign-existing-confirm-btn">이관 및 삭제 완료</button>
        <button class="btn-secondary" id="cat-reassign-cancel-btn">취소</button>
      </div>
    `;

    document.getElementById('cat-reassign-existing-confirm-btn')?.addEventListener('click', () => {
      const targetCatName = document.getElementById('cat-reassign-select')?.value;
      if (!targetCatName) return;

      state.transactions.forEach(t => {
        if (t.category === cat.name) {
          t.category = targetCatName;
        }
      });
      saveTransactions();

      const catIdx = targetList.findIndex(c => c.name === cat.name);
      if (catIdx !== -1) targetList.splice(catIdx, 1);

      const catInput = document.getElementById('tx-category');
      if (catInput && catInput.value === cat.name) {
        catInput.value = targetCatName;
      }

      renderCategoryGrid(txType);
      showToast(`'${cat.name}' 삭제 완료 (기존 내역 ➔ '${targetCatName}' 이관)`);
      closeModal();
    });

    document.getElementById('cat-reassign-cancel-btn')?.addEventListener('click', closeModal);
  };

  // View 2B-2: Create New Category & Reassign
  const renderReassignNewView = () => {
    if (titleEl) titleEl.textContent = `✨ 새 카테고리 생성 후 이관`;

    bodyEl.innerHTML = `
      <div class="form-group">
        <label for="cat-new-reassign-input">새로 생성할 카테고리 이름</label>
        <input type="text" id="cat-new-reassign-input" class="form-input" placeholder="예: 외식비, 경조사 등" autocomplete="off">
      </div>
      <div style="display: flex; gap: 8px; margin-top: 16px;">
        <button class="submit-btn" id="cat-reassign-new-confirm-btn">생성 및 이관 완료</button>
        <button class="btn-secondary" id="cat-reassign-cancel-btn">취소</button>
      </div>
    `;

    const newCreatedInput = document.getElementById('cat-new-reassign-input');
    if (newCreatedInput) newCreatedInput.focus();

    document.getElementById('cat-new-reassign-input')?.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        document.getElementById('cat-reassign-new-confirm-btn')?.click();
      }
    });

    document.getElementById('cat-reassign-new-confirm-btn')?.addEventListener('click', () => {
      const newCatName = (document.getElementById('cat-new-reassign-input')?.value || '').trim();
      if (!newCatName) {
        alert('새 카테고리 이름을 입력해주세요.');
        return;
      }
      if (targetList.some(c => c.name === newCatName)) {
        alert(`이미 존재하는 카테고리 이름입니다: '${newCatName}'`);
        return;
      }

      // 1. Add new category to targetList
      targetList.push({ name: newCatName, emoji: '📌', color: '#6366f1', type: txType });

      // 2. Reassign transactions
      state.transactions.forEach(t => {
        if (t.category === cat.name) {
          t.category = newCatName;
        }
      });
      saveTransactions();

      // 3. Remove old category
      const catIdx = targetList.findIndex(c => c.name === cat.name);
      if (catIdx !== -1) targetList.splice(catIdx, 1);

      const catInput = document.getElementById('tx-category');
      if (catInput && catInput.value === cat.name) {
        catInput.value = newCatName;
      }

      renderCategoryGrid(txType);
      showToast(`새 카테고리 '${newCatName}' 생성 및 내역 이관 완료!`);
      closeModal();
    });

    document.getElementById('cat-reassign-cancel-btn')?.addEventListener('click', closeModal);
  };

  renderMainChoice();
  overlay.classList.add('active');
}

export function renderCategoryGrid(txType = 'expense') {
  const grid = document.getElementById('category-grid');
  if (!grid) return;
  grid.innerHTML = '';

  const catInput = document.getElementById('tx-category');
  const targetList = txType === 'income' ? INCOME_CATEGORIES : EXPENSE_CATEGORIES;
  
  let selectedCatName = catInput ? catInput.value : (targetList[0]?.name || '');
  if (!targetList.some(c => c.name === selectedCatName)) {
    selectedCatName = targetList[0]?.name || '';
    if (catInput) catInput.value = selectedCatName;
  }

  targetList.forEach((cat) => {
    const chip = document.createElement('div');
    const isSelected = cat.name === selectedCatName;
    chip.className = `category-chip ${isSelected ? 'selected' : ''}`;
    chip.dataset.name = cat.name;

    chip.innerHTML = `
      <span class="cat-emoji">${cat.emoji}</span>
      <span class="cat-label">${cat.name}</span>
    `;

    let pressTimer = null;
    let isLongPress = false;

    const startPress = () => {
      isLongPress = false;
      pressTimer = setTimeout(() => {
        isLongPress = true;
        handleCategoryLongPress(cat, txType);
      }, 550);
    };

    const cancelPress = () => {
      if (pressTimer) {
        clearTimeout(pressTimer);
        pressTimer = null;
      }
    };

    chip.addEventListener('mousedown', startPress);
    chip.addEventListener('touchstart', startPress, { passive: true });
    chip.addEventListener('mouseup', cancelPress);
    chip.addEventListener('mouseleave', cancelPress);
    chip.addEventListener('touchend', cancelPress);
    chip.addEventListener('touchcancel', cancelPress);

    chip.addEventListener('click', (e) => {
      if (isLongPress) {
        e.stopPropagation();
        e.preventDefault();
        isLongPress = false;
        return;
      }
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
    const typeLabelText = txType === 'income' ? '수입' : '지출';
    const newName = prompt(`추가할 새 ${typeLabelText} 카테고리 명칭을 입력하세요:`);
    if (newName && newName.trim()) {
      const cleanName = newName.trim();
      if (!targetList.some(c => c.name === cleanName)) {
        targetList.push({ name: cleanName, emoji: '📌', color: '#6366f1', type: txType });
        if (catInput) catInput.value = cleanName;
        renderCategoryGrid(txType);
        showToast(`'${cleanName}' ${typeLabelText} 카테고리가 추가되었습니다!`);
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

  const typeExpense = document.getElementById('type-expense');
  if (typeExpense) typeExpense.checked = true;

  if (txDateInput) txDateInput.value = state.selectedDateStr;
  if (txAmountInput) txAmountInput.value = '';
  if (txMemoInput) txMemoInput.value = '';
  if (txRecurringInput) txRecurringInput.checked = false;

  renderAccountSelectOptions('expense');
  renderCategoryGrid('expense');
  if (txModalOverlay) txModalOverlay.classList.add('active');
}

export function closeTxModal() {
  const txModalOverlay = document.getElementById('tx-modal-overlay');
  if (txModalOverlay) txModalOverlay.classList.remove('active');
}

export function setupModalForms(onRenderApp) {
  const typeExpenseRadio = document.getElementById('type-expense');
  const typeIncomeRadio = document.getElementById('type-income');
  [typeExpenseRadio, typeIncomeRadio].forEach(radio => {
    if (radio) {
      radio.addEventListener('change', () => {
        const txType = document.querySelector('input[name="tx-type"]:checked')?.value || 'expense';
        renderAccountSelectOptions(txType);
        renderCategoryGrid(txType);
      });
    }
  });

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
