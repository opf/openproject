import type { AllowedValue } from './formSchema';

export type LastSelection = Record<string, AllowedValue>;

let remembered:{ document:string; selection:LastSelection } | undefined;

// Another document comes with its own preconditions, so the selection is kept for
// the document at hand alone: a page load drops it, a Turbo visit hits the key.
function documentKey():string {
  return typeof window === 'undefined' ? '' : window.location.pathname;
}

export function lastSelection():LastSelection {
  return remembered?.document === documentKey() ? remembered.selection : {};
}

/** Replaces the whole selection, so an attribute left empty stays empty next time. */
export function rememberSelection(selection:LastSelection):void {
  remembered = { document: documentKey(), selection };
}

export function forgetLastSelection():void {
  remembered = undefined;
}
