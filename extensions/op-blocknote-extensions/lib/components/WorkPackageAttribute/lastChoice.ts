import type { AttributeChoice } from './pending';
import { documentKey } from '../../utils/documentKey';

let remembered:{ document:string, choice:AttributeChoice } | undefined;


export function lastAttributeChoice():AttributeChoice | undefined {
  return remembered?.document === documentKey() ? remembered.choice : undefined;
}

export function rememberAttributeChoice(choice:AttributeChoice):void {
  remembered = { document: documentKey(), choice };
}

export function forgetAttributeChoice():void {
  remembered = undefined;
}
