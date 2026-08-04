export interface IconProps {
  /** Lucide icon name, e.g. "droplet", "pill", "activity" (see lucide.dev/icons) */
  name: string;
  /** Pixel size, square. Default 20. */
  size?: number;
  /** CSS color; defaults to currentColor so it inherits surrounding text/icon color. */
  color?: string;
  style?: React.CSSProperties;
  className?: string;
}
export function Icon(props: IconProps): JSX.Element;
