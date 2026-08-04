import React from 'react';

export function Card({ children, padding = 'var(--space-6)', style, ...rest }) {
  return (
    <div
      style={{
        background: 'var(--color-surface)', border: '1px solid var(--color-border)',
        borderRadius: 'var(--radius-card)', boxShadow: 'var(--shadow-sm)', padding,
        ...style,
      }}
      {...rest}
    >
      {children}
    </div>
  );
}
