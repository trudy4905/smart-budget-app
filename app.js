/* ==========================================================================
   SMART BUDGET APP v6.0 - MODULAR ES ENGINE ENTRYPOINT
   ========================================================================== */

import {
  state,
  loadAccounts,
  loadRecurringRules,
  loadTransactions,
  loadActiveViewDate,
  applyRecurringRules,
  checkAutoCardSettlements,
  saveActiveViewDate,
  setSelectedDateStr,
  setCurrentDate
} from './js/state.js';

import {
  formatDate,
  updateLiveClock
} from './js/helpers.js';

import {
  renderAccountTabs,
  renderHeaderSummary,
  updateHeaderVisibilityForView,
  initMonthPickerBtn
} from './js/header.js';

import { initDrawer, renderDrawerChecklist, renderDrawerAmounts } from './js/drawer.js';
import { renderCalendar } from './js/calendar.js';
import { renderDailyDetail } from './js/daily-detail.js';
import { renderStatsView } from './js/stats.js';
import { renderSettingsView } from './js/settings.js';

import {
  renderCategoryGrid,
  renderAccountSelectOptions,
  toggleAccTypeFields,
  openTxModal,
  closeTxModal,
  openAccModal,
  closeAccModal,
  setupModalForms
} from './js/modals.js';

// --- CORE RENDER FUNCTION ---
export function renderApp() {
  const activeTab = document.querySelector('.nav-tab.active');
  const activeViewId = activeTab ? activeTab.dataset.view : 'calendar';
  updateHeaderVisibilityForView(activeViewId);

  try { renderDrawerChecklist(renderApp); } catch (e) { console.error('renderDrawerChecklist error:', e); }
  try { renderDrawerAmounts(); } catch (e) { console.error('renderDrawerAmounts error:', e); }
  try { renderAccountTabs(renderApp); } catch (e) { console.error('renderAccountTabs error:', e); }
  try { renderAccountSelectOptions(); } catch (e) { console.error('renderAccountSelectOptions error:', e); }
  try { renderHeaderSummary(renderApp); } catch (e) { console.error('renderHeaderSummary error:', e); }
  try { renderCalendar(renderApp); } catch (e) { console.error('renderCalendar error:', e); }
  try { renderDailyDetail(renderApp); } catch (e) { console.error('renderDailyDetail error:', e); }
  try { renderStatsView(); } catch (e) { console.error('renderStatsView error:', e); }
  try { renderSettingsView(renderApp); } catch (e) { console.error('renderSettingsView error:', e); }

  if (window.lucide) {
    try { lucide.createIcons(); } catch (e) { console.error('lucide error:', e); }
  }
}

// --- INITIALIZATION ENGINE ---
let isInitialized = false;

function startApp() {
  if (!isInitialized) {
    init();
    isInitialized = true;
  } else {
    renderApp();
  }
}

function init() {
  loadAccounts();
  loadRecurringRules();
  loadTransactions();
  loadActiveViewDate();

  applyRecurringRules();
  checkAutoCardSettlements();

  renderCategoryGrid();
  renderApp();

  try {
    initDrawer(renderApp);
    initMonthPickerBtn(renderApp);
    setupEventListeners();
    setupModalForms(renderApp);
  } catch (e) {
    console.error('setupEventListeners error:', e);
  }

  updateLiveClock();
  setInterval(updateLiveClock, 60000);
}

// --- EVENT LISTENERS & NAVIGATION ---
function setupEventListeners() {
  const safeAddListener = (id, event, handler) => {
    const el = document.getElementById(id);
    if (el) el.addEventListener(event, handler);
  };

  const accTypeBank = document.getElementById('acc-type-bank');
  const accTypeCard = document.getElementById('acc-type-card');
  const accTypeDebit = document.getElementById('acc-type-debit');

  [accTypeBank, accTypeCard, accTypeDebit].forEach(el => {
    if (el) el.addEventListener('change', toggleAccTypeFields);
  });

  safeAddListener('prev-month-btn', 'click', () => {
    setCurrentDate(new Date(state.currentDate.getFullYear(), state.currentDate.getMonth() - 1, 1));
    setSelectedDateStr(formatDate(state.currentDate));
    saveActiveViewDate();
    applyRecurringRules();
    renderApp();
  });

  safeAddListener('next-month-btn', 'click', () => {
    setCurrentDate(new Date(state.currentDate.getFullYear(), state.currentDate.getMonth() + 1, 1));
    setSelectedDateStr(formatDate(state.currentDate));
    saveActiveViewDate();
    applyRecurringRules();
    renderApp();
  });

  safeAddListener('today-btn', 'click', () => {
    const now = new Date();
    setCurrentDate(new Date(now.getFullYear(), now.getMonth(), 1));
    setSelectedDateStr(formatDate(now));
    saveActiveViewDate();
    applyRecurringRules();
    renderApp();
  });

  // Month Carousel Mouse Drag / Touch Swipe helper
  const carouselContainer = document.getElementById('month-carousel');
  if (carouselContainer) {
    let isDown = false;
    let startX = 0;
    let scrollLeft = 0;
    let hasMoved = false;

    carouselContainer.addEventListener('mousedown', (e) => {
      isDown = true;
      hasMoved = false;
      startX = e.pageX - carouselContainer.offsetLeft;
      scrollLeft = carouselContainer.scrollLeft;
    });

    carouselContainer.addEventListener('mouseleave', () => { isDown = false; });
    carouselContainer.addEventListener('mouseup', () => { isDown = false; });
    carouselContainer.addEventListener('mousemove', (e) => {
      if (!isDown) return;
      const x = e.pageX - carouselContainer.offsetLeft;
      const walk = (x - startX) * 1.5;
      if (Math.abs(walk) > 5) hasMoved = true;
      carouselContainer.scrollLeft = scrollLeft - walk;
    });

    carouselContainer.addEventListener('click', (e) => {
      if (hasMoved) {
        e.stopPropagation();
        e.preventDefault();
        hasMoved = false;
      }
    }, true);
  }

  // FAB Button Actions
  const fabMainPlusBtn = document.getElementById('fab-main-plus-btn');
  if (fabMainPlusBtn) {
    fabMainPlusBtn.addEventListener('click', () => openTxModal('expense'));
  }

  // Navigation tab clicks
  const tabs = document.querySelectorAll('.nav-tab');
  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const viewId = tab.dataset.view;
      document.querySelectorAll('.app-view').forEach(v => v.classList.remove('active'));
      const targetView = document.getElementById(`view-${viewId}`);
      if (targetView) targetView.classList.add('active');

      const fabGroup = document.getElementById('fab-group');
      if (fabGroup) {
        fabGroup.style.display = (viewId === 'calendar') ? 'flex' : 'none';
      }

      updateHeaderVisibilityForView(viewId);
    });
  });

  // Modal Buttons
  const txModalOverlay = document.getElementById('tx-modal-overlay');
  const fabIncomeBtn = document.getElementById('fab-income-btn');
  const fabExpenseBtn = document.getElementById('fab-expense-btn');
  const closeModalBtn = document.getElementById('close-modal-btn');
  const fabGroup = document.getElementById('fab-group');

  if (fabGroup) fabGroup.style.display = 'flex';
  if (fabIncomeBtn) fabIncomeBtn.addEventListener('click', () => openTxModal('income'));
  if (fabExpenseBtn) fabExpenseBtn.addEventListener('click', () => openTxModal('expense'));
  if (closeModalBtn) closeModalBtn.addEventListener('click', closeTxModal);

  if (txModalOverlay) {
    txModalOverlay.addEventListener('click', (e) => {
      if (e.target === txModalOverlay) closeTxModal();
    });
  }

  const accModalOverlay = document.getElementById('acc-modal-overlay');
  const openAccModalBtn = document.getElementById('open-account-modal-btn');
  const settingsAddBankBtn = document.getElementById('settings-add-bank-btn');
  const settingsAddCardBtn = document.getElementById('settings-add-card-btn');
  const closeAccModalBtn = document.getElementById('close-acc-modal-btn');

  if (openAccModalBtn) openAccModalBtn.addEventListener('click', () => openAccModal('bank'));
  if (settingsAddBankBtn) settingsAddBankBtn.addEventListener('click', () => openAccModal('bank'));
  if (settingsAddCardBtn) settingsAddCardBtn.addEventListener('click', () => openAccModal('card'));
  if (closeAccModalBtn) closeAccModalBtn.addEventListener('click', closeAccModal);

  if (accModalOverlay) {
    accModalOverlay.addEventListener('click', (e) => {
      if (e.target === accModalOverlay) closeAccModal();
    });
  }

  document.querySelectorAll('#acc-color-grid .color-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('#acc-color-grid .color-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const colorInput = document.getElementById('acc-color');
      if (colorInput) colorInput.value = chip.dataset.color;
    });
  });

  document.querySelectorAll('.amount-chips .chip-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const amountInput = document.getElementById('tx-amount');
      if (!amountInput) return;
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
      const paymentInput = document.getElementById('tx-payment');
      if (paymentInput) paymentInput.value = pill.dataset.pm;
    });
  });
}

// App lifecycle startup
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', startApp);
} else {
  startApp();
}

window.addEventListener('load', startApp);
window.addEventListener('pageshow', startApp);
