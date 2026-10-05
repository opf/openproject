import type { AllowedValue } from './formSchema';
import { documentKey } from '../../utils/documentKey';

export type LastSelection = Record<string, AllowedValue>;

// Kept per document: another one comes with its own preconditions.
let remembered:{ document:string; selection:LastSelection } | undefined;

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
