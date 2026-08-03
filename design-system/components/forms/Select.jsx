import React from 'react';
import { Icon } from '../core/Icon';

export function Select({ label, value, onChange, options, style }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, ...style }}>
      {label && <label style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--color-text-secondary)' }}>{label}</label>}
      <div style={{ position: 'relative' }}>
        <select
          value={value}
          onChange={onChange}
          style={{
            width: '100%', appearance: 'none', border: '1px solid var(--color-border-strong)',
            borderRadius: 'var(--radius-input)', padding: '11px 38px 11px 14px', background: 'var(--color-surface)',
            fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)',
          }}
        >
          {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <Icon name="chevron-down" size={16} color="var(--color-text-muted)" style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }} />
      </div>
    </div>
  );
}
