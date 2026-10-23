export type HalFilter = Record<string, { operator:string; values:string[] }>;

export function typeaheadFilter(query:string):HalFilter {
  return { typeahead: { operator: '**', values: [query] } };
}
