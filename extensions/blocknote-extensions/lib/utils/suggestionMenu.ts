import { SuggestionMenu } from '@blocknote/core/extensions';
import type { AnyEditor } from '../editorTypes';

/** Dismisses the open suggestion menu, leaving the typed text untouched. */
export function closeSuggestionMenu(editor:AnyEditor):void {
  editor.getExtension(SuggestionMenu)?.closeMenu();
}
