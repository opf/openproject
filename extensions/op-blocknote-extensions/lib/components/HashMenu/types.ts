import type { WorkPackage } from '../../openProjectTypes';

export interface HashMenuItem {
  title:string;
  onItemClick:() => void;
}

export interface HashSearchState {
  query:string;
  results:WorkPackage[];
  error:string | null;
}

export function isHashWpQuery(query:string):boolean {
  return query.trim().length > 0;
}