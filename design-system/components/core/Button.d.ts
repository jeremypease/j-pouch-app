/**
 * @startingPoint section="Components" subtitle="Primary, secondary, ghost & danger button" viewport="700x200"
 */
export interface ButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  /** Lucide icon name shown alongside the label */
  icon?: string;
  iconPosition?: 'left' | 'right';
  disabled?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export function Button(props: ButtonProps): JSX.Element;
