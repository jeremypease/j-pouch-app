export interface TabBarItem { label: string; value: string; icon: string; }
export interface TabBarProps {
  items: TabBarItem[];
  active: string;
  onChange?: (value: string) => void;
}
export function TabBar(props: TabBarProps): JSX.Element;
