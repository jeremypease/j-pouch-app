export interface IconButtonProps {
  /** Lucide icon name */
  icon: string;
  /** Accessible label (no visible text) */
  label: string;
  variant?: 'filled' | 'soft' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
  style?: React.CSSProperties;
}
export function IconButton(props: IconButtonProps): JSX.Element;
