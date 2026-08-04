/**
 * @startingPoint section="Components" subtitle="Bottom sheet modal" viewport="700x420"
 */
export interface DialogProps {
  open: boolean;
  title: string;
  children: React.ReactNode;
  onClose?: () => void;
  footer?: React.ReactNode;
}
export function Dialog(props: DialogProps): JSX.Element | null;
