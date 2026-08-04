/**
 * @startingPoint section="Components" subtitle="Dashboard metric tile with trend" viewport="700x220"
 */
export interface StatCardProps {
  label: string;
  value: string | number;
  unit?: string;
  /** Lucide icon name */
  icon: string;
  /** Percent change vs last period; positive/negative/omit */
  trend?: number;
  style?: React.CSSProperties;
}
export function StatCard(props: StatCardProps): JSX.Element;
