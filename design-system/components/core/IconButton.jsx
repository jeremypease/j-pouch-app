import React from 'react';
import { Icon } from './Icon';

const SIZES = { sm: 32, md: 40, lg: 48 };
const VARIANTS = {
  filled: { background: 'var(--color-primary)', color: 'var(--color-text-on-primary)' },
  soft: { background: 'var(--color-primary-soft)', color: 'var(--color-primary)' },
  ghost: { background: 'transparent', color: 'var(--color-text-secondary)' },
};

export function IconButton({ icon, label, variant = 'ghost', size = 'md', style, ...rest }) {
  const dim = SIZES[size] || SIZES.md;
  const v = VARIANTS[variant] || VARIANTS.ghost;
  return (
    <button
      aria-label={label}
      style={{
        width: dim, height: dim, borderRadius: 'var(--radius-pill)', border: 'none',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        transition: 'background var(--duration-fast) var(--ease-out), transform var(--duration-fast) var(--ease-out)',
        ...v, ...style,
      }}
      style-hover={{ background: variant === 'filled' ? 'var(--color-primary-hover)' : 'var(--color-primary-soft)' }}
      style-active={{ transform: 'scale(0.94)' }}
      {...rest}
    >
      <Icon name={icon} size={dim * 0.5} />
    </button>
  );
}
