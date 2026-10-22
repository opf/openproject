import type { KeyboardEvent as ReactKeyboardEvent } from 'react';

export function buttonActivationProps(label:string) {
  return {
    role: 'button' as const,
    tabIndex: 0,
    'aria-label': label,
    onKeyDown: (event:ReactKeyboardEvent<HTMLElement>) => {
      if (event.key !== 'Enter' && event.key !== ' ') return;
      event.preventDefault();
      event.currentTarget.click();
    },
  };
}
