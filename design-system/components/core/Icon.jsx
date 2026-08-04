import React from 'react';
const BASE = 'https://unpkg.com/lucide-static@0.462.0/icons/';
export function Icon({ name, size = 20, color = 'currentColor', style, className, ...rest }) {
  const url = BASE + name + '.svg';
  return (
    <span
      aria-hidden="true"
      className={className}
      style={{
        display: 'inline-block', width: size, height: size, flexShrink: 0,
        backgroundColor: color,
        WebkitMaskImage: `url(${url})`, maskImage: `url(${url})`,
        WebkitMaskSize: 'contain', maskSize: 'contain',
        WebkitMaskRepeat: 'no-repeat', maskRepeat: 'no-repeat',
        WebkitMaskPosition: 'center', maskPosition: 'center',
        ...style,
      }}
      {...rest}
    />
  );
}
