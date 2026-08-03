const { Button, Input, Select, Checkbox, IconButton } = window.JPouchDesignSystem_6e602e;

const SYMPTOMS = ['Cramping', 'Nausea', 'Urgency', 'Bloating'];

function LogEntry({ onBack, onSave }) {
  const [consistency, setConsistency] = React.useState('formed');
  const [symptoms, setSymptoms] = React.useState([]);
  const toggle = s => setSymptoms(v => v.includes(s) ? v.filter(x => x !== s) : [...v, s]);
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--color-surface)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 'var(--space-5)', borderBottom: '1px solid var(--color-border)' }}>
        <IconButton icon="chevron-left" label="Back" variant="ghost" onClick={onBack} />
        <span style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-bold)', fontSize: 'var(--text-lg)', color: 'var(--color-text-primary)' }}>Log output</span>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: 'var(--space-5)', display: 'flex', flexDirection: 'column', gap: 'var(--space-5)' }}>
        <Input label="Time" mono defaultValue="3:42 PM" />
        <Select label="Consistency" value={consistency} onChange={e => setConsistency(e.target.value)} options={[{ label: 'Liquid', value: 'liquid' }, { label: 'Loose', value: 'loose' }, { label: 'Formed', value: 'formed' }]} />
        <div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-sm)', fontWeight: 'var(--weight-medium)', color: 'var(--color-text-secondary)', marginBottom: 10 }}>Symptoms (optional)</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {SYMPTOMS.map(s => <Checkbox key={s} label={s} checked={symptoms.includes(s)} onChange={() => toggle(s)} />)}
          </div>
        </div>
        <Input label="Note" placeholder="Anything else worth remembering?" />
      </div>
      <div style={{ padding: 'var(--space-5)', borderTop: '1px solid var(--color-border)' }}>
        <Button variant="primary" size="lg" style={{ width: '100%' }} onClick={onSave}>Save entry</Button>
      </div>
    </div>
  );
}
window.LogEntry = LogEntry;
