import React from 'react';
import { IconButton } from '../core/IconButton';

export function Dialog({ open, title, children, onClose, footer }) {
  if (!open) return null;
  return (
    <div style={{
      position: 'absolute', inset: 0, background: 'rgba(28,33,31,0.4)',
      display: 'flex', alignItems: 'flex-end', justifyContent: 'center', zIndex: 50,
    }} onClick={onClose}>
      <div onClick={e => e.stopPropagation()} style={{
        width: '100%', maxWidth: 420, background: 'var(--color-surface)', borderRadius: '24px 24px 0 0',
        boxShadow: 'var(--shadow-lg)', padding: 'var(--space-6)', display: 'flex', flexDirection: 'column', gap: 16,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-xl)', color: 'var(--color-text-primary)' }}>{title}</span>
          <IconButton icon="x" label="Close" variant="ghost" size="sm" onClick={onClose} />
        </div>
        <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-secondary)' }}>{children}</div>
        {footer && <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>{footer}</div>}
      </div>
    </div>
  );
}
