/* ==========================================================================
   ANALYTICS & STATS VIEW ENGINE
   ========================================================================== */

import { state, isTransactionMatchingSelection, setCategoryChartInstance } from './state.js';
import { CATEGORIES } from './constants.js';
import { parseLocalDateStr, formatNumber } from './helpers.js';

export function renderStatsView() {
  const periodText = document.getElementById('stats-period-text');
  const breakdownList = document.getElementById('category-breakdown-list');

  if (!periodText || !breakdownList) return;

  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();
  const accName = state.selectedAccountIds.includes('all') ? '전체 계좌' : 
    (state.selectedAccountIds.length === 1 ? (state.accounts.find(a => a.id === state.selectedAccountIds[0])?.name || '') : `선택 계좌 ${state.selectedAccountIds.length}개`);
  periodText.textContent = `${year}년 ${month + 1}월 지출 통계 (${accName})`;

  const monthExpenses = state.transactions.filter(t => {
    const d = parseLocalDateStr(t.date);
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

export function renderChart(categoriesArray) {
  const canvas = document.getElementById('categoryChart');
  if (!canvas) return;

  if (state.categoryChartInstance) {
    try { state.categoryChartInstance.destroy(); } catch (e) {}
    setCategoryChartInstance(null);
  }

  if (!categoriesArray || categoriesArray.length === 0 || !window.Chart) return;

  try {
    const ctx = canvas.getContext('2d');
    const chart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: categoriesArray.map(c => `${c.emoji} ${c.name}`),
        datasets: [{
          data: categoriesArray.map(c => c.amount),
          backgroundColor: categoriesArray.map(c => c.color),
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
    setCategoryChartInstance(chart);
  } catch (e) {
    console.warn('Chart render skipped on current layout pass:', e);
  }
}
