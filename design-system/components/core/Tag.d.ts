export interface TagProps {
  children: React.ReactNode;
  /** Selected/filter-active state */
  active?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}
export function Tag(props: TagProps): JSX.Element;
