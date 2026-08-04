import React from 'react';
import { Icon } from './Icon';
import { Card } from './Card';

export function StatCard({ label, value, unit, icon, trend, tone = 'neutral', style }) {
  const trendColor = trend > 0 ? 'var(--color-success)' : trend < 0 ? 'var(--color-danger)' : 'var(--color-text-muted)';
  return (
    <Card padding="var(--space-5)" style={{ display: 'flex', flexDirection: 'column', gap: 10, minWidth: 150, ...style }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Icon name={icon} size={16} color="var(--color-primary)" />
        <span style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-xs)', color: 'var(--color-text-muted)', fontWeight: 'var(--weight-medium)' }}>{label}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-3xl)', fontWeight: 'var(--weight-semibold)', color: 'var(--color-text-primary)' }}>{value}</span>
        {unit && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-sm)', color: 'var(--color-text-muted)' }}>{unit}</span>}
      </div>
      {trend !== undefined && (
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-2xs)', color: trendColor, fontWeight: 'var(--weight-medium)' }}>
          {trend > 0 ? '↑' : trend < 0 ? '↓' : '—'} {Math.abs(trend)}% vs last week
        </span>
      )}
    </Card>
  );
}
