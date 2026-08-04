import React from 'react';
import { Icon } from '../core/Icon';

export function Checkbox({ label, checked, onChange, style }) {
  return (
    <label style={{ display: 'inline-flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)', ...style }}>
      <input type="checkbox" checked={checked} onChange={onChange} style={{ display: 'none' }} />
      <span style={{
        width: 22, height: 22, borderRadius: 7, flexShrink: 0,
        border: `1px solid ${checked ? 'var(--color-primary)' : 'var(--color-border-strong)'}`,
        background: checked ? 'var(--color-primary)' : 'var(--color-surface)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'background var(--duration-fast) var(--ease-out)',
      }}>
        {checked && <Icon name="check" size={14} color="var(--white)" />}
      </span>
      {label}
    </label>
  );
}
