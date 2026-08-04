export interface TabItem { label: string; value: string; }
export interface TabsProps {
  items: TabItem[];
  active: string;
  onChange?: (value: string) => void;
  style?: React.CSSProperties;
}
export function Tabs(props: TabsProps): JSX.Element;
