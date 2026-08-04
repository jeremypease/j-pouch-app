export interface SwitchProps {
  label?: string;
  checked: boolean;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  style?: React.CSSProperties;
}
export function Switch(props: SwitchProps): JSX.Element;
