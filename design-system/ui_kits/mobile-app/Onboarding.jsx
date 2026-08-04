const { Button, Icon } = window.JPouchDesignSystem_6e602e;

const SLIDES = [
  { icon: 'heart-pulse', title: 'Welcome to J-Pouch', body: "Your companion for j-pouch surgery, recovery, and life after — one place to track how you're doing." },
  { icon: 'activity', title: 'Track what matters', body: 'Output, hydration, medications, and symptoms — logged in seconds, so you can spot patterns instead of guessing.' },
  { icon: 'shield-check', title: 'Private, and yours', body: 'Your data stays with you. Share a summary with your care team only when you choose to.' },
];

function Onboarding({ onDone }) {
  const [i, setI] = React.useState(0);
  const s = SLIDES[i];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--color-bg)', padding: 'var(--space-7) var(--space-6)', boxSizing: 'border-box' }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 'var(--space-6)', textAlign: 'center' }}>
        <div style={{ width: 88, height: 88, borderRadius: '50%', background: 'var(--color-primary-soft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name={s.icon} size={40} color="var(--color-primary)" />
        </div>
        <div>
          <div style={{ fontFamily: 'var(--font-display)', fontWeight: 'var(--weight-extrabold)', fontSize: 'var(--text-2xl)', color: 'var(--color-text-primary)', marginBottom: 10, letterSpacing: 'var(--tracking-tight)' }}>{s.title}</div>
          <div style={{ fontFamily: 'var(--font-body)', fontSize: 'var(--text-md)', color: 'var(--color-text-secondary)', lineHeight: 'var(--leading-relaxed)', maxWidth: 300 }}>{s.body}</div>
        </div>
      </div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: 'var(--space-6)' }}>
        {SLIDES.map((_, idx) => <div key={idx} style={{ width: idx === i ? 20 : 6, height: 6, borderRadius: 3, background: idx === i ? 'var(--color-primary)' : 'var(--gray-200)', transition: 'width var(--duration-normal) var(--ease-out)' }} />)}
      </div>
      <Button variant="primary" size="lg" style={{ width: '100%' }} onClick={() => i < SLIDES.length - 1 ? setI(i + 1) : onDone()}>
        {i < SLIDES.length - 1 ? 'Continue' : 'Get started'}
      </Button>
    </div>
  );
}
window.Onboarding = Onboarding;
