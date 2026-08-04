import React from 'react';
import { Icon } from '../core/Icon';

const TONES = {
  neutral: { icon: 'info', color: 'var(--color-primary)' },
  success: { icon: 'check-circle', color: 'var(--color-success)' },
  danger: { icon: 'alert-circle', color: 'var(--color-danger)' },
};

export function Toast({ message, tone = 'neutral', onClose, style }) {
  const t = TONES[tone] || TONES.neutral;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10, background: 'var(--gray-900)', color: 'var(--white)',
      padding: '13px 16px', borderRadius: 'var(--radius-md)', boxShadow: 'var(--shadow-lg)',
      fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', maxWidth: 340, ...style,
    }}>
      <Icon name={t.icon} size={17} color={t.color} />
      <span style={{ flex: 1 }}>{message}</span>
      {onClose && <Icon name="x" size={15} color="var(--gray-400)" style={{ cursor: 'pointer' }} onClick={onClose} />}
    </div>
  );
}
