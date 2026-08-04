const { Card, Tabs, Icon } = window.JPouchDesignSystem_6e602e;

const WEEK = [2, 4, 3, 5, 3, 2, 4];
const DAYS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

function Insights() {
  const [range, setRange] = React.useState('w');
  const max = Math.max(...WEEK);
  return (
    <div style={{ height: '100%', overflowY: 'auto', background: 'var(--color-bg)' }}>
      <div style={{ padding: 'var(--space-6) var(--space-5) var(--space-4)' }}>
        <div style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-extrabold)', fontSize: 'var(--text-2xl)', color: 'var(--color-text-primary)', letterSpacing: 'var(--tracking-tight)', marginBottom: 14 }}>Insights</div>
        <Tabs items={[{ label: 'Week', value: 'w' }, { label: 'Month', value: 'm' }]} active={range} onChange={setRange} />
      </div>
      <div style={{ padding: '0 var(--space-5)' }}>
        <Card>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', color: 'var(--color-text-muted)', marginBottom: 16 }}>Output per day</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: 100 }}>
            {WEEK.map((v, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ width: '100%', maxWidth: 26, height: `${(v / max) * 80}px`, background: 'var(--color-primary)', borderRadius: 6 }} />
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 'var(--text-2xs)', color: 'var(--color-text-muted)' }}>{DAYS[i]}</span>
              </div>
            ))}
          </div>
        </Card>
        <Card style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
          <Icon name="trending-down" size={20} color="var(--color-success)" />
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', color: 'var(--color-text-primary)' }}>Output frequency is trending down compared to last week.</div>
        </Card>
      </div>
      <div style={{ height: 90 }} />
    </div>
  );
}
window.Insights = Insights;
