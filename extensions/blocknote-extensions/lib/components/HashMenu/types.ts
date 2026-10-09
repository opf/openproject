import type { SuggestionMenuItem } from '../../hooks/useSuggestionSearch';

export type HashMenuItem = SuggestionMenuItem;

export function isHashWpQuery(query:string):boolean {
  return query.trim().length > 0;
}
