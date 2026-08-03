import React from 'react';

export function Switch({ checked, onChange, label, style }) {
  return (
    <label style={{ display: 'inline-flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)', ...style }}>
      <input type="checkbox" checked={checked} onChange={onChange} style={{ display: 'none' }} />
      <span style={{
        width: 42, height: 26, borderRadius: 'var(--radius-pill)', flexShrink: 0, position: 'relative',
        background: checked ? 'var(--color-primary)' : 'var(--gray-200)',
        transition: 'background var(--duration-normal) var(--ease-out)',
      }}>
        <span style={{
          position: 'absolute', top: 3, left: checked ? 19 : 3, width: 20, height: 20, borderRadius: '50%',
          background: 'var(--white)', boxShadow: 'var(--shadow-xs)', transition: 'left var(--duration-normal) var(--ease-out)',
        }} />
      </span>
      {label}
    </label>
  );
}
