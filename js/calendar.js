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
