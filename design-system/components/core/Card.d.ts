/**
 * @startingPoint section="Components" subtitle="Base surface container" viewport="700x220"
 */
export interface CardProps {
  children: React.ReactNode;
  padding?: string | number;
  style?: React.CSSProperties;
}
export function Card(props: CardProps): JSX.Element;
