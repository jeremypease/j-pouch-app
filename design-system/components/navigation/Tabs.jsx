import React from 'react';

export function Tabs({ items, active, onChange, style }) {
  return (
    <div style={{ display: 'flex', gap: 4, background: 'var(--gray-100)', padding: 4, borderRadius: 'var(--radius-pill)', ...style }}>
      {items.map(it => (
        <button key={it.value} onClick={() => onChange && onChange(it.value)} style={{
          flex: 1, border: 'none', padding: '8px 16px', borderRadius: 'var(--radius-pill)', cursor: 'pointer',
          fontFamily: 'var(--font-body)', fontWeight: 'var(--weight-semibold)', fontSize: 'var(--text-sm)',
          background: active === it.value ? 'var(--color-surface)' : 'transparent',
          color: active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)',
          boxShadow: active === it.value ? 'var(--shadow-xs)' : 'none',
          transition: 'background var(--duration-fast) var(--ease-out)',
        }}>{it.label}</button>
      ))}
    </div>
  );
}
