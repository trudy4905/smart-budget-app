/* ==========================================================================
   UTILITY & HELPER FUNCTIONS
   ========================================================================== */

export function parseLocalDateStr(dateStr) {
  if (!dateStr) return new Date();
  if (dateStr instanceof Date) return dateStr;
  const parts = String(dateStr).split('T')[0].split('-');
  if (parts.length >= 3) {
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  }
  return new Date(dateStr);
}

export function formatDate(d) {
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function formatNumber(num) {
  return (num || 0).toLocaleString('ko-KR');
}

export function formatCompactNumber(num) {
  if (num >= 1000000) return (num / 10000).toFixed(0) + '만';
  if (num >= 10000) return (num / 10000).toFixed(0) + '만';
  if (num >= 1000) return (num / 1000).toFixed(0) + '천';
  return num.toString();
}

export function updateLiveClock() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const timeEl = document.getElementById('status-time');
  if (timeEl) timeEl.textContent = `${hours}:${minutes}`;
}

export function showToast(message) {
  const toast = document.getElementById('toast');
  const toastMsg = document.getElementById('toast-message');
  if (!toast || !toastMsg) return;
  toastMsg.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 2800);
}
