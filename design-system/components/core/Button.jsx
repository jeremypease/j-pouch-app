import React from 'react';
import { Icon } from './Icon';

const VARIANTS = {
  primary: { background: 'var(--color-primary)', color: 'var(--color-text-on-primary)', border: '1px solid transparent' },
  secondary: { background: 'var(--color-surface)', color: 'var(--color-primary)', border: '1px solid var(--color-border-strong)' },
  ghost: { background: 'transparent', color: 'var(--color-primary)', border: '1px solid transparent' },
  danger: { background: 'var(--color-danger)', color: 'var(--white)', border: '1px solid transparent' },
};
const HOVER = {
  primary: { background: 'var(--color-primary-hover)' },
  secondary: { background: 'var(--color-primary-soft)' },
  ghost: { background: 'var(--color-primary-soft)' },
  danger: { background: '#8a3c2c' },
};
const SIZES = {
  sm: { padding: '8px 14px', fontSize: 'var(--text-sm)', borderRadius: 'var(--radius-button)', gap: 6 },
  md: { padding: '12px 20px', fontSize: 'var(--text-md)', borderRadius: 'var(--radius-button)', gap: 8 },
  lg: { padding: '16px 26px', fontSize: 'var(--text-lg)', borderRadius: 'var(--radius-button)', gap: 10 },
};

export function Button({ children, variant = 'primary', size = 'md', icon, iconPosition = 'left', disabled, style, ...rest }) {
  const v = VARIANTS[variant] || VARIANTS.primary;
  const h = HOVER[variant] || HOVER.primary;
  const s = SIZES[size] || SIZES.md;
  return (
    <button
      disabled={disabled}
      style={{
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: s.gap,
        fontFamily: 'var(--font-body)', fontWeight: 'var(--weight-semibold)', fontSize: s.fontSize,
        padding: s.padding, borderRadius: s.borderRadius, cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.45 : 1, transition: `background var(--duration-fast) var(--ease-out), transform var(--duration-fast) var(--ease-out)`,
        ...v, ...style,
      }}
      style-hover={!disabled ? h : {}}
      style-active={!disabled ? { transform: 'scale(0.98)' } : {}}
      {...rest}
    >
      {icon && iconPosition === 'left' && <Icon name={icon} size={s.fontSize === 'var(--text-lg)' ? 20 : 16} />}
      {children}
      {icon && iconPosition === 'right' && <Icon name={icon} size={s.fontSize === 'var(--text-lg)' ? 20 : 16} />}
    </button>
  );
}
