const { Card, StatCard, Badge, Icon, IconButton } = window.JPouchDesignSystem_6e602e;

const ENTRIES = [
  { time: '7:12 AM', consistency: 'Formed', note: '' },
  { time: '11:40 AM', consistency: 'Loose', note: 'After coffee' },
  { time: '3:05 PM', consistency: 'Formed', note: '' },
];

function Header({ title, subtitle }) {
  return (
    <div style={{ padding: 'var(--space-6) var(--space-5) var(--space-4)' }}>
      <div style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-extrabold)', fontSize: 'var(--text-2xl)', color: 'var(--color-text-primary)', letterSpacing: 'var(--tracking-tight)' }}>{title}</div>
      {subtitle && <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', color: 'var(--color-text-muted)', marginTop: 4 }}>{subtitle}</div>}
    </div>
  );
}

function Home({ onOpenEntry }) {
  return (
    <div style={{ height: '100%', overflowY: 'auto', background: 'var(--color-bg)' }}>
      <Header title="Good afternoon" subtitle="12 weeks since takedown" />
      <div style={{ padding: '0 var(--space-5)', display: 'flex', gap: 12 }}>
        <StatCard label="Output today" value={3} unit="times" icon="activity" trend={-12} style={{ flex: 1 }} />
        <StatCard label="Hydration" value="1.4" unit="L" icon="droplets" trend={8} style={{ flex: 1 }} />
      </div>
      <div style={{ padding: 'var(--space-6) var(--space-5) var(--space-3)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-lg)', color: 'var(--color-text-primary)' }}>Today's log</span>
        <Badge tone="success" icon="check">On track</Badge>
      </div>
      <div style={{ padding: '0 var(--space-5)', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {ENTRIES.map((e, i) => (
          <Card key={i} padding="14px 16px" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--color-primary-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name="droplet" size={16} color="var(--color-primary)" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', fontWeight: 'var(--weight-medium)', color: 'var(--color-text-primary)' }}>{e.consistency}{e.note && <span style={{ color: 'var(--color-text-muted)', fontWeight: 'var(--weight-regular)' }}> · {e.note}</span>}</div>
            </div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-xs)', color: 'var(--color-text-muted)' }}>{e.time}</div>
          </Card>
        ))}
      </div>
      <div style={{ padding: 'var(--space-6) var(--space-5)' }}>
        <Card padding="14px 16px" style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }} onClick={onOpenEntry}>
          <Icon name="pill" size={18} color="var(--color-accent-hover)" />
          <div style={{ flex: 1, fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', color: 'var(--color-text-primary)' }}>Time for your evening dose of loperamide.</div>
          <IconButton icon="chevron-right" label="Details" size="sm" variant="ghost" />
        </Card>
      </div>
      <div style={{ height: 90 }} />
    </div>
  );
}
window.Home = Home;
