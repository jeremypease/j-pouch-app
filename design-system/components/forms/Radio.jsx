import React from 'react';

export function Radio({ label, checked, onChange, style }) {
  return (
    <label style={{ display: 'inline-flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)', ...style }}>
      <input type="radio" checked={checked} onChange={onChange} style={{ display: 'none' }} />
      <span style={{
        width: 22, height: 22, borderRadius: '50%', flexShrink: 0,
        border: `1px solid ${checked ? 'var(--color-primary)' : 'var(--color-border-strong)'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {checked && <span style={{ width: 11, height: 11, borderRadius: '50%', background: 'var(--color-primary)' }} />}
      </span>
      {label}
    </label>
  );
}
