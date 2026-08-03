import React from 'react';

export function Tag({ children, active = false, onClick, style }) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'inline-flex', alignItems: 'center', fontFamily: 'var(--font-body)',
        fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', padding: '7px 14px',
        borderRadius: 'var(--radius-pill)', cursor: onClick ? 'pointer' : 'default',
        border: active ? '1px solid var(--color-primary)' : '1px solid var(--color-border-strong)',
        background: active ? 'var(--color-primary-soft)' : 'var(--color-surface)',
        color: active ? 'var(--teal-700)' : 'var(--color-text-secondary)',
        transition: 'background var(--duration-fast) var(--ease-out)',
        ...style,
      }}
      style-hover={{ background: 'var(--color-primary-soft)' }}
    >
      {children}
    </button>
  );
}
