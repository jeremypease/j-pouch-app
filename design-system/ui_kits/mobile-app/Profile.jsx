const { Card, Switch, Icon, Badge } = window.JPouchDesignSystem_6e602e;

function Row({ icon, label, right }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0', borderBottom: '1px solid var(--color-border)' }}>
      <Icon name={icon} size={18} color="var(--color-text-secondary)" />
      <span style={{ flex: 1, fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-primary)' }}>{label}</span>
      {right}
    </div>
  );
}

function Profile() {
  const [hydration, setHydration] = React.useState(true);
  const [meds, setMeds] = React.useState(true);
  return (
    <div style={{ height: '100%', overflowY: 'auto', background: 'var(--color-bg)' }}>
      <div style={{ padding: 'var(--space-6) var(--space-5) var(--space-4)', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'var(--color-primary)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-lg)' }}>A</div>
        <div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-lg)', color: 'var(--color-text-primary)' }}>Alex</div>
          <Badge tone="info">Adjustment phase</Badge>
        </div>
      </div>
      <div style={{ padding: '0 var(--space-5)' }}>
        <Card padding="0 16px">
          <Row icon="droplets" label="Hydration reminders" right={<Switch checked={hydration} onChange={e => setHydration(e.target.checked)} />} />
          <Row icon="pill" label="Medication reminders" right={<Switch checked={meds} onChange={e => setMeds(e.target.checked)} />} />
          <Row icon="ruler" label="Units" right={<span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-sm)', color: 'var(--color-text-muted)' }}>Metric</span>} />
          <div style={{ padding: '14px 0' }}><Row icon="share-2" label="Share summary with care team" right={<Icon name="chevron-right" size={16} color="var(--color-text-muted)" />} /></div>
        </Card>
      </div>
      <div style={{ height: 90 }} />
    </div>
  );
}
window.Profile = Profile;
