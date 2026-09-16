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

export function bindLongPress(element, onLongPress) {
  if (!element) return () => false;

  element.style.webkitUserSelect = 'none';
  element.style.userSelect = 'none';
  element.style.webkitTouchCallout = 'none';

  let timer = null;
  let isLong = false;
  let startX = 0, startY = 0;

  const start = (e) => {
    if (e.button !== undefined && e.button !== 0) return;
    isLong = false;
    startX = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
    startY = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : 0);

    clearTimeout(timer);
    timer = setTimeout(() => {
      isLong = true;
      if (navigator.vibrate) {
        try { navigator.vibrate(40); } catch (err) {}
      }
      onLongPress(e);
    }, 380);
  };

  const move = (e) => {
    if (!timer) return;
    const curX = e.clientX || (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
    const curY = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : 0);
    if (Math.abs(curX - startX) > 15 || Math.abs(curY - startY) > 15) {
      clearTimeout(timer);
      timer = null;
    }
  };

  const end = () => {
    clearTimeout(timer);
    timer = null;
  };

  // Pointer events
  element.addEventListener('pointerdown', start);
  element.addEventListener('pointermove', move);
  element.addEventListener('pointerup', end);
  element.addEventListener('pointercancel', end);

  // Fallback touch events for iOS older webkit
  element.addEventListener('touchstart', start, { passive: true });
  element.addEventListener('touchmove', move, { passive: true });
  element.addEventListener('touchend', end);
  element.addEventListener('touchcancel', end);

  element.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    clearTimeout(timer);
    isLong = true;
    onLongPress(e);
  });

  // Capture phase click handler to block default action if long pressed
  element.addEventListener('click', (e) => {
    if (isLong) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      setTimeout(() => { isLong = false; }, 300);
      return false;
    }
  }, true);

  return () => isLong;
}
