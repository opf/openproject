export interface HashMenuItem {
  title: string;
  onItemClick: () => void;
}

export function isHashWpQuery(query: string): boolean {
  return query.trim().length > 0;
}