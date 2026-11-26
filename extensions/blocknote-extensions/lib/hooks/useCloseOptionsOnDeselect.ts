import { useEffect, useRef } from 'react';
import type { OptionsMenu } from './useOptionsMenu';

export function useCloseOptionsOnDeselect(isSelected:boolean, options:OptionsMenu):void {
  const wasSelected = useRef(isSelected);
  const { isOpen, close } = options;

  useEffect(() => {
    if (wasSelected.current && !isSelected && isOpen) close();
    wasSelected.current = isSelected;
  }, [isSelected, isOpen, close]);
}
