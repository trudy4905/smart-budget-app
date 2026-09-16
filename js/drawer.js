/* ==========================================================================
   SIDEBAR DRAWER ENGINE
   ========================================================================== */

import { state, setSelectedAccountIds, setDrawerFilter } from './state.js';
import { openAccModal } from './modals.js';

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
}

export function initDrawer(onRenderApp) {
  const openBtn = document.getElementById('open-drawer-btn');
  const closeBtn = document.getElementById('close-drawer-btn');
  const overlay = document.getElementById('drawer-overlay');
  const addAccBtn = document.getElementById('drawer-add-account-btn');
  const quickAddAccBtn = document.getElementById('drawer-quick-add-acc-btn');

  if (openBtn) openBtn.addEventListener('click', openDrawer);
  if (closeBtn) closeBtn.addEventListener('click', closeDrawer);
  if (overlay) overlay.addEventListener('click', closeDrawer);

  if (addAccBtn) {
    addAccBtn.addEventListener('click', () => {
      closeDrawer();
      openAccModal('bank');
    });
  }

  if (quickAddAccBtn) {
    quickAddAccBtn.addEventListener('click', () => {
      closeDrawer();
      openAccModal('bank');
    });
  }

  // Drawer top menu filters ("전체 자산", "현금지출", "카드지출", "전체 지출")
  document.querySelectorAll('.drawer-menu-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const filter = btn.dataset.filter || 'all';
      setDrawerFilter(filter);
      
      document.querySelectorAll('.drawer-menu-item').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      if (onRenderApp) onRenderApp();
    });
  });

  renderDrawerChecklist(onRenderApp);
}

export function renderDrawerChecklist(onRenderApp) {
  const container = document.getElementById('drawer-account-checklist');
  if (!container) return;
  container.innerHTML = '';

  const isAllActive = state.selectedAccountIds.includes('all') || state.selectedAccountIds.length === 0;

  // Master Checkbox: 전체 자산 선택
  const masterItem = document.createElement('label');
  masterItem.className = 'drawer-checkbox-item master';
  const masterChecked = isAllActive;
  masterItem.innerHTML = `
    <input type="checkbox" id="chk-acc-all" ${masterChecked ? 'checked' : ''}>
    <span class="chk-box-custom ${masterChecked ? 'checked' : ''}">
      <i data-lucide="check"></i>
    </span>
    <span class="chk-label-text">전체 캘린더 (모든 계좌)</span>
  `;

  masterItem.querySelector('input').addEventListener('change', (e) => {
    if (e.target.checked) {
      setSelectedAccountIds(['all']);
    } else {
      setSelectedAccountIds([]);
    }
    if (onRenderApp) onRenderApp();
  });
  container.appendChild(masterItem);

  // Individual Account Checkboxes
  state.accounts.forEach(acc => {
    const isChecked = isAllActive || state.selectedAccountIds.includes(acc.id);
    const accItem = document.createElement('label');
    accItem.className = 'drawer-checkbox-item';
    
    const isCredit = acc.type === 'card' && acc.cardKind === 'credit';
    const isDebit = acc.type === 'card' && acc.cardKind === 'debit';
    const iconBadge = isCredit ? '💳' : (isDebit ? '💳' : '🏦');

    accItem.innerHTML = `
      <input type="checkbox" value="${acc.id}" ${isChecked ? 'checked' : ''}>
      <span class="chk-box-custom ${isChecked ? 'checked' : ''}" style="--acc-color: ${acc.color || '#4f46e5'}">
        <i data-lucide="check"></i>
      </span>
      <span class="chk-label-text">${iconBadge} ${acc.name}</span>
    `;

    accItem.querySelector('input').addEventListener('change', () => {
      const checkedInputs = container.querySelectorAll('input[type="checkbox"]:not(#chk-acc-all):checked');
      const selectedIds = Array.from(checkedInputs).map(inp => inp.value);

      if (selectedIds.length === 0 || selectedIds.length === state.accounts.length) {
        setSelectedAccountIds(['all']);
      } else {
        setSelectedAccountIds(selectedIds);
      }
      if (onRenderApp) onRenderApp();
    });

    container.appendChild(accItem);
  });

  if (window.lucide) lucide.createIcons();
}
