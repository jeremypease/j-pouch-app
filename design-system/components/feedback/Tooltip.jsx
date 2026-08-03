import React from 'react';

export function Tooltip({ children, label, style }) {
  const [open, setOpen] = React.useState(false);
  return (
    <span style={{ position: 'relative', display: 'inline-flex' }} onMouseEnter={() => setOpen(true)} onMouseLeave={() => setOpen(false)}>
      {children}
      {open && (
        <span style={{
          position: 'absolute', bottom: '125%', left: '50%', transform: 'translateX(-50%)',
          background: 'var(--gray-900)', color: 'var(--white)', fontFamily: 'var(--font-body)', fontSize: 'var(--text-xs)',
          padding: '6px 10px', borderRadius: 'var(--radius-sm)', whiteSpace: 'nowrap', boxShadow: 'var(--shadow-md)', zIndex: 10,
          ...style,
        }}>{label}</span>
      )}
    </span>
  );
}
