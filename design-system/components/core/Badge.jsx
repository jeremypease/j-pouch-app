import React from 'react';
import { Icon } from './Icon';

const TONES = {
  neutral: { bg: 'var(--gray-100)', fg: 'var(--gray-700)' },
  success: { bg: 'var(--color-success-soft)', fg: 'var(--teal-700)' },
  warning: { bg: 'var(--color-warning-soft)', fg: 'var(--tan-700)' },
  danger: { bg: 'var(--color-danger-soft)', fg: 'var(--red-600)' },
  info: { bg: 'var(--color-info-soft)', fg: 'var(--blue-600)' },
};

export function Badge({ children, tone = 'neutral', icon, style }) {
  const t = TONES[tone] || TONES.neutral;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      background: t.bg, color: t.fg, fontFamily: 'var(--font-body)', fontWeight: 'var(--weight-semibold)',
      fontSize: 'var(--text-xs)', padding: '4px 10px', borderRadius: 'var(--radius-pill)', lineHeight: 1.4,
      ...style,
    }}>
      {icon && <Icon name={icon} size={12} color={t.fg} />}
      {children}
    </span>
  );
}
