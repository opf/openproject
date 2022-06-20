import { ID } from '@datorama/akita';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';

export interface IProjectAutocompleteItem {
  id:ID;
  href:string;
  name:string;
  disabled:boolean;
  disabledReason?:string;
  ancestors:IHalResourceLink[];
  numberOfAncestors?:number;
}

export interface IProjectAutocompleteItemTree {
  id:ID;
  href:string;
  name:string;
  disabled:boolean;
  disabledReason?:string;
  children:IProjectAutocompleteItemTree[];
}
