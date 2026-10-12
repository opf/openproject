import type { ComponentProps } from 'react';
import { getPrimerDialogs } from '../../services/dialogComponents';
import { Button } from './Button';

export function DialogButton({ $primary, ...props }:ComponentProps<'button'> & { $primary?:boolean }) {
  const primer = getPrimerDialogs();
  return primer
    ? <primer.Button {...props} variant={$primary ? 'primary' : 'default'} />
    : <Button {...props} $primary={$primary} />;
}
