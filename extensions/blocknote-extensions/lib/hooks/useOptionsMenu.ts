import { useCallback, useState } from 'react';

interface OptionsMenuState {
  isOpen:boolean;
  // A menu the keyboard opened takes the focus; one a pointer opened leaves it in the editor.
  takesFocus:boolean;
}

const CLOSED:OptionsMenuState = { isOpen: false, takesFocus: false };

export interface OptionsMenu extends OptionsMenuState {
  open:(takesFocus:boolean) => void;
  toggle:(takesFocus:boolean) => void;
  close:() => void;
}

export function useOptionsMenu():OptionsMenu {
  const [state, setState] = useState(CLOSED);

  const open = useCallback((takesFocus:boolean) => setState({ isOpen: true, takesFocus }), []);
  const toggle = useCallback((takesFocus:boolean) => {
    setState((previous) => (previous.isOpen ? CLOSED : { isOpen: true, takesFocus }));
  }, []);
  const close = useCallback(() => setState(CLOSED), []);

  return { ...state, open, toggle, close };
}
