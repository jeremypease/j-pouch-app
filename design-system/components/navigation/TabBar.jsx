import React from 'react';
import { Icon } from '../core/Icon';

export function TabBar({ items, active, onChange }) {
  return (
    <div style={{
      display: 'flex', background: 'rgba(255,255,255,0.85)', backdropFilter: 'blur(var(--blur-glass))',
      WebkitBackdropFilter: 'blur(var(--blur-glass))', borderTop: '1px solid var(--color-border)',
      padding: '8px 4px calc(8px + env(safe-area-inset-bottom, 0px))',
    }}>
      {items.map(it => (
        <button key={it.value} onClick={() => onChange && onChange(it.value)} style={{
          flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, border: 'none',
          background: 'none', cursor: 'pointer', padding: '6px 0',
          color: active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)',
        }}>
          <Icon name={it.icon} size={22} color={active === it.value ? 'var(--color-primary)' : 'var(--color-text-muted)'} />
          <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-2xs)', fontWeight: 'var(--weight-medium)' }}>{it.label}</span>
        </button>
      ))}
    </div>
  );
}
