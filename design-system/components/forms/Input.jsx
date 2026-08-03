import React from 'react';

export function Input({ label, helper, error, prefix, suffix, mono, style, id, ...rest }) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, '-');
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, ...style }}>
      {label && <label htmlFor={inputId} style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--color-text-secondary)' }}>{label}</label>}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8, background: 'var(--color-surface)',
        border: `1px solid ${error ? 'var(--color-danger)' : 'var(--color-border-strong)'}`,
        borderRadius: 'var(--radius-input)', padding: '11px 14px',
      }}>
        {prefix && <span style={{ color: 'var(--color-text-muted)', fontSize: 'var(--text-sm)' }}>{prefix}</span>}
        <input
          id={inputId}
          style={{
            border: 'none', outline: 'none', flex: 1, background: 'transparent',
            fontFamily: mono ? 'var(--font-mono)' : 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)',
          }}
          {...rest}
        />
        {suffix && <span style={{ color: 'var(--color-text-muted)', fontSize: 'var(--text-sm)' }}>{suffix}</span>}
      </div>
      {(helper || error) && (
        <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-xs)', color: error ? 'var(--color-danger)' : 'var(--color-text-muted)' }}>{error || helper}</span>
      )}
    </div>
  );
}
