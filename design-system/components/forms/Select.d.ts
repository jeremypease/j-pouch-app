export interface SelectOption { label: string; value: string; }
export interface SelectProps {
  label?: string;
  value: string;
  options: SelectOption[];
  onChange?: (e: React.ChangeEvent<HTMLSelectElement>) => void;
  style?: React.CSSProperties;
}
export function Select(props: SelectProps): JSX.Element;
