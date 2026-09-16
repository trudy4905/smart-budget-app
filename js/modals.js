/* ==========================================================================
   MODALS, DROPDOWNS & FORM CONTROLLERS
   ========================================================================== */

import { state, setEditingAccountId, setSelectedDateStr, setCurrentDate, saveActiveViewDate, saveAccounts, saveTransactions, saveRecurringRules, setSelectedAccountIds, getCardBillForMonth } from './state.js';
import { BANKS_LIST, CARDS_LIST, CATEGORIES, EXPENSE_CATEGORIES, INCOME_CATEGORIES } from './constants.js';
import { parseLocalDateStr, showToast, formatNumber } from './helpers.js';
import { deleteAccount } from './settings.js';

export function formatFormattedNumberInput(value) {
  if (value === undefined || value === null) return '';
  const str = String(value);
  const isNegative = str.includes('-');
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

  const prevValue = bankSelect.value;

  bankSelect.innerHTML = '';
  const list = isCardType ? CARDS_LIST : BANKS_LIST;

  list.forEach(item => {
    const opt = document.createElement('option');
    opt.value = item.name;
    opt.textContent = `${item.icon} ${item.name}`;
    bankSelect.appendChild(opt);
  });

  if (prevValue && Array.from(bankSelect.options).some(o => o.value === prevValue)) {
    bankSelect.value = prevValue;
  }
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
  overlay.onclick = (e) => {
    if (e.target === overlay) closeModal();
  };

  // View 1: Main Choice (수정 / 삭제 버튼만 깔끔히 표시)
  const renderMainChoice = () => {
    if (titleEl) titleEl.textContent = `${cat.emoji} ${cat.name}`;

    bodyEl.innerHTML = `
      <div style="display: flex; gap: 10px; margin-top: 6px;">
        <button class="action-choice-btn" id="cat-btn-edit" style="flex: 1; margin: 0; justify-content: center; padding: 12px; font-size: 0.95rem; font-weight: 700;">
          ✏️ 수정
        </button>
        <button class="action-choice-btn danger" id="cat-btn-delete" style="flex: 1; margin: 0; justify-content: center; padding: 12px; font-size: 0.95rem; font-weight: 700;">
          🗑️ 삭제
        </button>
      </div>
    `;

    document.getElementById('cat-btn-edit')?.addEventListener('click', () => renderEditView());
    document.getElementById('cat-btn-delete')?.addEventListener('click', () => renderDeleteView());
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

export function setSelectedColor(targetColor = '#6366f1') {
  const accColorInput = document.getElementById('acc-color');
  if (accColorInput) accColorInput.value = targetColor;

  const presetChips = document.querySelectorAll('#acc-color-grid .color-chip:not(.custom-color-chip)');
  const customChip = document.getElementById('acc-custom-color-btn');
  const customInput = document.getElementById('acc-custom-color-input');
  const customIconEl = document.getElementById('acc-custom-color-icon');

  const checkSvg = '<svg viewBox="0 0 24 24" width="22" height="22" stroke="#ffffff" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round" style="pointer-events: none;"><polyline points="20 6 9 17 4 12"></polyline></svg>';

  let foundPreset = false;

  presetChips.forEach(chip => {
    const isMatch = (chip.dataset.color || '').toLowerCase() === (targetColor || '').toLowerCase();
    chip.classList.toggle('active', isMatch);
    if (isMatch) {
      foundPreset = true;
      chip.innerHTML = checkSvg;
    } else {
      chip.innerHTML = '';
    }
  });

  if (customChip) {
    if (!foundPreset) {
      customChip.classList.add('active');
      customChip.style.background = targetColor;
      customChip.dataset.color = targetColor;
      if (customInput) customInput.value = targetColor;
      if (customIconEl) customIconEl.innerHTML = checkSvg;
    } else {
      customChip.classList.remove('active');
      customChip.style.background = 'conic-gradient(from 180deg at 50% 50%, #FF0000 0deg, #FFFF00 60deg, #00FF00 120deg, #00FFFF 180deg, #0000FF 240deg, #FF00FF 300deg, #FF0000 360deg)';
      delete customChip.dataset.color;
      if (customIconEl) customIconEl.innerHTML = '<span style="font-size: 18px; pointer-events: none;">🎨</span>';
    }
  }
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
  } else {
    if (titleEl) titleEl.textContent = isCardMode ? '새 카드 등록' : '새 계좌 / 통장 등록';
    if (saveBtn) saveBtn.innerHTML = '<i data-lucide="check"></i> 등록하기';

    if (isCardMode && accCardRadio) {
      accCardRadio.checked = true;
    } else if (accBankRadio) {
      accBankRadio.checked = true;
    }
  }

  // Hide or show the Account Type section based on mode
  if (isCardMode) {
    if (accTypeGroup) accTypeGroup.style.display = 'block';
    if (accTypeLabel) accTypeLabel.textContent = '카드 종류';
    if (accTypeBankLabel) accTypeBankLabel.style.display = 'none';
  } else {
    if (accTypeGroup) accTypeGroup.style.display = 'none';
  }

  // First populate dropdown options based on radios
  toggleAccTypeFields();
  renderAccountSelectOptions();

  // Then set form input values (after dropdowns are populated)
  if (isEditing) {
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
    setSelectedColor(targetColor);

  } else {
    if (accNameInput) accNameInput.value = '';
    if (accNumberInput) accNumberInput.value = '';
    if (accBalanceInput) accBalanceInput.value = '0';

    setSelectedColor('#6366f1');
  }

  if (window.lucide) lucide.createIcons();
  if (accModalOverlay) accModalOverlay.classList.add('active');
}

export function closeAccModal() {
  setEditingAccountId(null);
  const accModalOverlay = document.getElementById('acc-modal-overlay');
  if (accModalOverlay) accModalOverlay.classList.remove('active');
}

export function openTxModal(defaultType = 'expense') {
  const txModalOverlay = document.getElementById('tx-modal-overlay');
  const txDateInput = document.getElementById('tx-date');
  const txAmountInput = document.getElementById('tx-amount');
  const txMemoInput = document.getElementById('tx-memo');
  const txRecurringInput = document.getElementById('tx-is-recurring');

  const typeExpenseRadio = document.getElementById('type-expense');
  const typeIncomeRadio = document.getElementById('type-income');

  const txType = (defaultType === 'income') ? 'income' : 'expense';

  if (txType === 'income') {
    if (typeIncomeRadio) typeIncomeRadio.checked = true;
  } else {
    if (typeExpenseRadio) typeExpenseRadio.checked = true;
  }

  if (txDateInput) txDateInput.value = state.selectedDateStr;
  if (txAmountInput) txAmountInput.value = '';
  if (txMemoInput) txMemoInput.value = '';
  if (txRecurringInput) txRecurringInput.checked = false;

  renderAccountSelectOptions(txType);
  renderCategoryGrid(txType);
  if (window.lucide) lucide.createIcons();
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

  // Account Color Picker Handlers
  const colorGrid = document.getElementById('acc-color-grid');
  if (colorGrid) {
    colorGrid.addEventListener('click', (e) => {
      const chip = e.target.closest('.color-chip');
      if (!chip || chip.classList.contains('custom-color-chip')) return;
      const color = chip.dataset.color;
      if (color) {
        setSelectedColor(color);
      }
    });
  }

  const customColorInput = document.getElementById('acc-custom-color-input');
  if (customColorInput) {
    const handleCustomColor = (e) => {
      const val = e.target.value;
      if (val) setSelectedColor(val);
    };
    customColorInput.addEventListener('input', handleCustomColor);
    customColorInput.addEventListener('change', handleCustomColor);
  }

  // Initial color state setup
  setSelectedColor('#6366f1');

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
      const date = document.getElementById('tx-date')?.value || state.selectedDateStr;
      const isRecurring = document.getElementById('tx-is-recurring')?.checked || false;
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

  // Summary Card Detail Modal Triggers
  const cardIncome = document.getElementById('summary-card-income');
  const cardCash = document.getElementById('summary-card-cash');
  const cardCredit = document.getElementById('summary-card-credit');
  const cardTotalExpense = document.getElementById('summary-card-total-expense');

  if (cardIncome) cardIncome.addEventListener('click', () => openSummaryDetailModal('income'));
  if (cardCash) cardCash.addEventListener('click', () => openSummaryDetailModal('cash'));
  if (cardCredit) cardCredit.addEventListener('click', () => openSummaryDetailModal('credit-card'));
  if (cardTotalExpense) cardTotalExpense.addEventListener('click', () => openSummaryDetailModal('total-expense'));

  const closeSummaryDetailBtn = document.getElementById('close-summary-detail-modal-btn');
  const closeSummaryDetailBottomBtn = document.getElementById('close-summary-detail-modal-bottom-btn');
  const summaryDetailOverlay = document.getElementById('summary-detail-modal-overlay');

  if (closeSummaryDetailBtn) closeSummaryDetailBtn.addEventListener('click', closeSummaryDetailModal);
  if (closeSummaryDetailBottomBtn) closeSummaryDetailBottomBtn.addEventListener('click', closeSummaryDetailModal);
  if (summaryDetailOverlay) {
    summaryDetailOverlay.addEventListener('click', (e) => {
      if (e.target === summaryDetailOverlay) closeSummaryDetailModal();
    });
  }
}

export function openSummaryDetailModal(type = 'credit-card') {
  const overlay = document.getElementById('summary-detail-modal-overlay');
  const titleEl = document.getElementById('summary-detail-title');
  const emojiEl = document.getElementById('summary-detail-emoji');
  const totalLabelEl = document.getElementById('summary-detail-total-label');
  const totalAmountEl = document.getElementById('summary-detail-total-amount');
  const listEl = document.getElementById('summary-detail-list');

  if (!overlay || !listEl) return;

  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();

  if (type === 'credit-card') {
    if (emojiEl) emojiEl.textContent = '💳';
    if (titleEl) titleEl.textContent = '신용카드별 지출 & 결제일';
    if (totalLabelEl) totalLabelEl.textContent = '당월 카드 지출 총액';

    const creditCards = state.accounts.filter(a => a.type === 'card' && (a.cardKind === 'credit' || !a.cardKind));
    
    let totalCardBill = 0;
    listEl.innerHTML = '';

    if (creditCards.length === 0) {
      listEl.innerHTML = '<p style="font-size: 0.85rem; color: var(--text-muted); padding: 16px 0; text-align: center;">등록된 신용카드가 없습니다.</p>';
    } else {
      creditCards.forEach(card => {
        const bill = getCardBillForMonth(card.id, year, month);
        totalCardBill += bill;
        const pDay = card.paymentDay || 25;

        const item = document.createElement('div');
        item.style.cssText = 'display: flex; align-items: center; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid var(--border-color);';
        item.innerHTML = `
          <div style="display: flex; align-items: center; gap: 10px;">
            <span class="acc-color-dot" style="background: ${card.color || '#ec4899'}; width: 14px; height: 14px; border-radius: 50%; flex-shrink: 0;"></span>
            <div>
              <div style="font-weight: 700; font-size: 0.9rem; color: var(--text-main);">${card.name} (${card.bank})</div>
              <div style="font-size: 0.76rem; color: var(--text-muted); margin-top: 2px;">다음달 ${pDay}일 결제</div>
            </div>
          </div>
          <div style="font-weight: 700; font-size: 0.95rem; color: #a855f7;">₩${formatNumber(bill)}</div>
        `;
        listEl.appendChild(item);
      });
    }

    if (totalAmountEl) totalAmountEl.textContent = `₩${formatNumber(totalCardBill)}`;

  } else if (type === 'income') {
    if (emojiEl) emojiEl.textContent = '💵';
    if (titleEl) titleEl.textContent = '이번 달 수입 상세';
    if (totalLabelEl) totalLabelEl.textContent = '수입 총액';
    
    const incomeTxs = state.transactions.filter(t => {
      const d = parseLocalDateStr(t.date);
      return t.type === 'income' && d.getFullYear() === year && d.getMonth() === month;
    });

    let total = 0;
    listEl.innerHTML = '';
    if (incomeTxs.length === 0) {
      listEl.innerHTML = '<p style="font-size: 0.85rem; color: var(--text-muted); padding: 16px 0; text-align: center;">이번 달 수입 내역이 없습니다.</p>';
    } else {
      incomeTxs.forEach(tx => {
        total += Number(tx.amount);
        const item = document.createElement('div');
        item.style.cssText = 'display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid var(--border-color);';
        item.innerHTML = `
          <div>
            <div style="font-weight: 600; font-size: 0.85rem; color: var(--text-main);">${tx.category} - ${tx.memo || '수입'}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${tx.date}</div>
          </div>
          <div style="font-weight: 700; font-size: 0.9rem; color: var(--income-color);">+₩${formatNumber(tx.amount)}</div>
        `;
        listEl.appendChild(item);
      });
    }
    if (totalAmountEl) totalAmountEl.textContent = `₩${formatNumber(total)}`;

  } else if (type === 'cash') {
    if (emojiEl) emojiEl.textContent = '👛';
    if (titleEl) titleEl.textContent = '현금 / 체크 지출 내역';
    if (totalLabelEl) totalLabelEl.textContent = '즉시 출금 총액';

    const cashTxs = state.transactions.filter(t => {
      const d = parseLocalDateStr(t.date);
      const acc = state.accounts.find(a => a.id === t.accountId);
      const isCashDebit = !acc || acc.type === 'bank' || acc.cardKind === 'debit';
      return t.type === 'expense' && isCashDebit && d.getFullYear() === year && d.getMonth() === month;
    });

    let total = 0;
    listEl.innerHTML = '';
    if (cashTxs.length === 0) {
      listEl.innerHTML = '<p style="font-size: 0.85rem; color: var(--text-muted); padding: 16px 0; text-align: center;">이번 달 현금/체크 지출이 없습니다.</p>';
    } else {
      cashTxs.forEach(tx => {
        total += Number(tx.amount);
        const item = document.createElement('div');
        item.style.cssText = 'display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid var(--border-color);';
        item.innerHTML = `
          <div>
            <div style="font-weight: 600; font-size: 0.85rem; color: var(--text-main);">${tx.category} - ${tx.memo || '지출'}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${tx.date}</div>
          </div>
          <div style="font-weight: 700; font-size: 0.9rem; color: var(--expense-color);">-₩${formatNumber(tx.amount)}</div>
        `;
        listEl.appendChild(item);
      });
    }
    if (totalAmountEl) totalAmountEl.textContent = `₩${formatNumber(total)}`;

  } else if (type === 'total-expense') {
    if (emojiEl) emojiEl.textContent = '📊';
    if (titleEl) titleEl.textContent = '이번 달 총 지출 요약';
    if (totalLabelEl) totalLabelEl.textContent = '총 지출 합계';

    const expenseTxs = state.transactions.filter(t => {
      const d = parseLocalDateStr(t.date);
      return t.type === 'expense' && d.getFullYear() === year && d.getMonth() === month;
    });

    let total = 0;
    listEl.innerHTML = '';
    if (expenseTxs.length === 0) {
      listEl.innerHTML = '<p style="font-size: 0.85rem; color: var(--text-muted); padding: 16px 0; text-align: center;">이번 달 총 지출 내역이 없습니다.</p>';
    } else {
      expenseTxs.forEach(tx => {
        total += Number(tx.amount);
        const acc = state.accounts.find(a => a.id === tx.accountId);
        const accBadge = acc ? `${acc.name}` : '기타';
        const item = document.createElement('div');
        item.style.cssText = 'display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid var(--border-color);';
        item.innerHTML = `
          <div>
            <div style="font-weight: 600; font-size: 0.85rem; color: var(--text-main);">${tx.category} <span style="font-size: 0.75rem; color: var(--text-muted);">(${accBadge})</span></div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${tx.date} - ${tx.memo || ''}</div>
          </div>
          <div style="font-weight: 700; font-size: 0.9rem; color: #ec4899;">-₩${formatNumber(tx.amount)}</div>
        `;
        listEl.appendChild(item);
      });
    }
    if (totalAmountEl) totalAmountEl.textContent = `₩${formatNumber(total)}`;
  }

  if (window.lucide) lucide.createIcons();
  overlay.classList.add('active');
}

export function closeSummaryDetailModal() {
  const overlay = document.getElementById('summary-detail-modal-overlay');
  if (overlay) overlay.classList.remove('active');
}

export function showAccountActionModal(acc, onRenderApp) {
  const overlay = document.getElementById('item-action-modal-overlay');
  const titleEl = document.getElementById('item-action-modal-title');
  const subEl = document.getElementById('item-action-modal-sub');
  const editBtn = document.getElementById('item-action-edit-btn');
  const deleteBtn = document.getElementById('item-action-delete-btn');
  const closeBtn = document.getElementById('close-item-action-modal-btn');
  const cancelBtn = document.getElementById('item-action-cancel-btn');

  if (!overlay) return;

  const isCard = acc.type === 'card';
  const iconBadge = isCard ? (acc.cardKind === 'debit' ? '💳' : '💳') : '🏦';
  const typeText = isCard ? (acc.cardKind === 'debit' ? '체크카드' : '신용카드') : '입출금 통장';

  if (titleEl) titleEl.innerHTML = `${iconBadge} ${acc.name}`;
  if (subEl) subEl.textContent = `${acc.bank || ''} • ${typeText}`;

  const closeModal = () => {
    overlay.classList.remove('active');
  };

  overlay.classList.add('active');
  if (window.lucide) lucide.createIcons();

  // Replace buttons to clear previous event listeners cleanly
  const newEdit = editBtn.cloneNode(true);
  const newDelete = deleteBtn.cloneNode(true);
  const newClose = closeBtn.cloneNode(true);
  const newCancel = cancelBtn.cloneNode(true);

  editBtn.parentNode.replaceChild(newEdit, editBtn);
  deleteBtn.parentNode.replaceChild(newDelete, deleteBtn);
  closeBtn.parentNode.replaceChild(newClose, closeBtn);
  cancelBtn.parentNode.replaceChild(newCancel, cancelBtn);

  newClose.addEventListener('click', closeModal);
  newCancel.addEventListener('click', closeModal);
  setTimeout(() => {
    overlay.onclick = (e) => { if (e.target === overlay) closeModal(); };
  }, 150);

  newEdit.addEventListener('click', () => {
    closeModal();
    openAccModal(isCard ? 'card' : 'bank', acc);
  });

  newDelete.addEventListener('click', () => {
    closeModal();
    deleteAccount(acc.id, onRenderApp);
  });
}
