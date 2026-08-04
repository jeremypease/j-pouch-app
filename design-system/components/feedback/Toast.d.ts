export interface ToastProps {
  message: string;
  tone?: 'neutral' | 'success' | 'danger';
  onClose?: () => void;
  style?: React.CSSProperties;
}
export function Toast(props: ToastProps): JSX.Element;
