/* ==========================================================================
   CALENDAR VIEW ENGINE
   ========================================================================== */

import { state, isTransactionMatchingSelection, applyRecurringRules, saveActiveViewDate, setSelectedDateStr, setCurrentDate } from './state.js';
import { formatDate, parseLocalDateStr, formatCompactNumber } from './helpers.js';

export function renderCalendar(onRenderApp) {
  const grid = document.getElementById('calendar-grid');
  if (!grid) return;
  grid.innerHTML = '';

  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();

  const firstDay = new Date(year, month, 1);
  const startingDayOfWeek = firstDay.getDay();
  const totalDaysInMonth = new Date(year, month + 1, 0).getDate();
  const prevMonthDays = new Date(year, month, 0).getDate();
  const todayStr = formatDate(new Date());

  for (let i = startingDayOfWeek - 1; i >= 0; i--) {
    const prevDay = prevMonthDays - i;
    const prevMonthDateStr = formatDate(new Date(year, month - 1, prevDay));
    const cell = createCalendarCell(prevDay, prevMonthDateStr, true, false, false, onRenderApp);
    grid.appendChild(cell);
  }

  for (let day = 1; day <= totalDaysInMonth; day++) {
    const dateObj = new Date(year, month, day);
    const dateStr = formatDate(dateObj);
    const isToday = dateStr === todayStr;
    const isSelected = dateStr === state.selectedDateStr;

    const cell = createCalendarCell(day, dateStr, false, isToday, isSelected, onRenderApp);
    grid.appendChild(cell);
  }

  const totalCellsSoFar = startingDayOfWeek + totalDaysInMonth;
  const nextDaysNeeded = (totalCellsSoFar > 35 ? 42 : 35) - totalCellsSoFar;

  for (let day = 1; day <= nextDaysNeeded; day++) {
    const nextMonthDateStr = formatDate(new Date(year, month + 1, day));
    const cell = createCalendarCell(day, nextMonthDateStr, true, false, false, onRenderApp);
    grid.appendChild(cell);
  }
}

export function createCalendarCell(dayNum, dateStr, isOtherMonth, isToday = false, isSelected = false, onRenderApp) {
  const cell = document.createElement('div');
  cell.className = `calendar-cell ${isOtherMonth ? 'other-month' : ''} ${isToday ? 'today' : ''} ${isSelected ? 'selected' : ''}`;
  cell.dataset.date = dateStr;

  const numEl = document.createElement('span');
  numEl.className = 'day-number';
  numEl.textContent = dayNum;
  cell.appendChild(numEl);

  const dateTxs = state.transactions.filter(t => t.date === dateStr && isTransactionMatchingSelection(t));

  if (dateTxs.length > 0) {
    const itemsContainer = document.createElement('div');
    itemsContainer.className = 'cell-item-chips-wrapper';

    const maxVisible = 3;
    const visibleTxs = dateTxs.slice(0, maxVisible);
    const overflowCount = dateTxs.length - maxVisible;

    visibleTxs.forEach(t => {
      const chip = document.createElement('div');
      const txAcc = state.accounts.find(a => a.id === t.accountId);
      const isCard = txAcc && txAcc.type === 'card' && txAcc.cardKind === 'credit';
      const isExpense = t.type === 'expense';
      const isIncome = t.type === 'income';

      let chipClass = 'chip-schedule';
      let iconStr = '📌';
      let textStr = t.memo || t.category;

      if (isExpense) {
        if (isCard) {
          chipClass = 'chip-card-expense';
          iconStr = '💳';
          textStr = t.memo ? `${t.memo}-` : `${t.category}-`;
        } else {
          chipClass = 'chip-cash-expense';
          iconStr = '💰';
          if (t.amount > 0) {
            textStr = t.memo && !t.memo.includes('💰') ? `${t.memo}` : `-${formatCompactNumber(t.amount)}`;
          } else {
            textStr = t.memo || t.category;
          }
        }
      } else if (isIncome) {
        chipClass = 'chip-income';
        iconStr = '💵';
        textStr = `+${formatCompactNumber(t.amount)}`;
      } else if (t.isRecurring) {
        chipClass = 'chip-recurring';
        iconStr = '☑️';
      } else if (t.memo && (t.memo.includes('약속') || t.memo.includes('미팅') || t.memo.includes('연휴') || t.memo.includes('박람회'))) {
        chipClass = 'chip-event';
        iconStr = '🚩';
      }

      chip.className = `day-item-chip ${chipClass}`;
      chip.title = `${t.memo || t.category} (${t.type === 'expense' ? '-' : '+'}${t.amount}원)`;
      chip.innerHTML = `<span class="chip-icon">${iconStr}</span><span class="chip-text">${textStr}</span>`;

      chip.addEventListener('click', (e) => {
        e.stopPropagation();
        setSelectedDateStr(dateStr);
        const clickedDateObj = parseLocalDateStr(dateStr);
        if (clickedDateObj.getMonth() !== state.currentDate.getMonth() || clickedDateObj.getFullYear() !== state.currentDate.getFullYear()) {
          setCurrentDate(new Date(clickedDateObj.getFullYear(), clickedDateObj.getMonth(), 1));
          applyRecurringRules();
        }
        saveActiveViewDate();
        if (onRenderApp) onRenderApp();
      });

      itemsContainer.appendChild(chip);
    });

    if (overflowCount > 0) {
      const moreChip = document.createElement('div');
      moreChip.className = 'day-item-chip chip-more';
      moreChip.textContent = `+${overflowCount}개 더보기`;
      itemsContainer.appendChild(moreChip);
    }

    cell.appendChild(itemsContainer);
  }

  cell.addEventListener('click', () => {
    setSelectedDateStr(dateStr);
    const clickedDateObj = parseLocalDateStr(dateStr);
    if (clickedDateObj.getMonth() !== state.currentDate.getMonth() || clickedDateObj.getFullYear() !== state.currentDate.getFullYear()) {
      setCurrentDate(new Date(clickedDateObj.getFullYear(), clickedDateObj.getMonth(), 1));
      applyRecurringRules();
    }
    saveActiveViewDate();
    if (onRenderApp) onRenderApp();
  });

  return cell;
}
