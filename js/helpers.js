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
  let timer = null;
  let isLong = false;
  let startX = 0, startY = 0;

  const start = (e) => {
    isLong = false;
    const t = e.touches ? e.touches[0] : e;
    startX = t ? t.clientX : 0;
    startY = t ? t.clientY : 0;

    timer = setTimeout(() => {
      isLong = true;
      if (navigator.vibrate) {
        try { navigator.vibrate(40); } catch (err) {}
      }
      onLongPress(e);
    }, 450);
  };

  const cancel = (e) => {
    if (e.touches && e.touches.length > 0) {
      const t = e.touches[0];
      if (Math.abs(t.clientX - startX) > 10 || Math.abs(t.clientY - startY) > 10) {
        clearTimeout(timer);
        return;
      }
    }
    clearTimeout(timer);
  };

  element.addEventListener('touchstart', start, { passive: true });
  element.addEventListener('touchmove', cancel, { passive: true });
  element.addEventListener('touchend', cancel);
  element.addEventListener('touchcancel', cancel);

  element.addEventListener('mousedown', start);
  element.addEventListener('mousemove', cancel);
  element.addEventListener('mouseup', cancel);
  element.addEventListener('mouseleave', cancel);

  element.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    onLongPress(e);
  });

  return () => isLong;
}
