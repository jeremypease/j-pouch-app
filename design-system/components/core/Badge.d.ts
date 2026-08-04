export interface BadgeProps {
  children: React.ReactNode;
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'info';
  /** Optional leading Lucide icon */
  icon?: string;
  style?: React.CSSProperties;
}
export function Badge(props: BadgeProps): JSX.Element;
