/* ==========================================================================
   CONSTANTS & MASTER DATA
   ========================================================================== */

export const STORAGE_KEYS = {
  TX: 'smart_budget_transactions_v5.0',
  ACC: 'smart_budget_accounts_v5.0',
  REC: 'smart_budget_recurring_v5.0',
  LAST_DATE: 'smart_budget_last_date_v5.0'
};

export const BANKS_LIST = [
  { name: '신한은행', icon: '🏦' },
  { name: 'KB국민은행', icon: '💛' },
  { name: '카카오뱅크', icon: '💛' },
  { name: '토스뱅크', icon: '💙' },
  { name: '우리은행', icon: '💙' },
  { name: '하나은행', icon: '💚' },
  { name: 'NH농협', icon: '💚' },
  { name: 'IBK기업은행', icon: '🏦' },
  { name: 'SC제일은행', icon: '🏦' },
  { name: '현금/기타', icon: '💵' }
];

export const CARDS_LIST = [
  { name: '신한카드', icon: '💳' },
  { name: 'KB국민카드', icon: '💳' },
  { name: '현대카드', icon: '💳' },
  { name: '삼성카드', icon: '💳' },
  { name: '롯데카드', icon: '💳' },
  { name: 'BC카드', icon: '💳' },
  { name: 'NH농협카드', icon: '💳' },
  { name: '우리카드', icon: '💳' },
  { name: '하나카드', icon: '💳' },
  { name: '카카오페이카드', icon: '💛' },
  { name: '토스카드', icon: '💙' }
];

export const CATEGORIES = [
  { name: '식당', emoji: '🍽️', color: '#f43f5e', type: 'expense' },
  { name: '장보기', emoji: '🛒', color: '#fb923c', type: 'expense' },
  { name: '적금/저축', emoji: '💰', color: '#3b82f6', type: 'savings' },
  { name: '카페/디저트', emoji: '☕', color: '#a855f7', type: 'expense' },
  { name: '교통/차량', emoji: '🚌', color: '#06b6d4', type: 'expense' },
  { name: '문화/쇼핑', emoji: '🎬', color: '#ec4899', type: 'expense' },
  { name: '수입/월급', emoji: '💵', color: '#10b981', type: 'income' },
  { name: '기타', emoji: '🎁', color: '#64748b', type: 'expense' }
];
