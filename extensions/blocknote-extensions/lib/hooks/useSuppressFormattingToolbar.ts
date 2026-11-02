import { useEffect } from 'react';

interface ToolbarStore {
  state:boolean;
  setState:(value:boolean) => void;
  subscribe:(listener:() => void) => () => void;
}

interface ToolbarHost {
  getExtension:(key:string) => { store?:ToolbarStore } | undefined;
}

// Keeps BlockNote's built-in formatting toolbar closed while `active`. BlockNote
// re-opens it on any pointerup over a focused editor with a non-empty selection,
// and our chip/block holds a NodeSelection the whole time its popover is open -
// so each tap on a popover button would otherwise stack a second toolbar.
export function useSuppressFormattingToolbar(
  editor:ToolbarHost | undefined,
  active:boolean,
):void {
  useEffect(() => {
    if (!active || !editor) return;
    const store = editor.getExtension('formattingToolbar')?.store;
    if (!store) return;

    const enforceClosed = () => {
      if (store.state) store.setState(false);
    };
    enforceClosed();
    return store.subscribe(enforceClosed);
  }, [editor, active]);
}
