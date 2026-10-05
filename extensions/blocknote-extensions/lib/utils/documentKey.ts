// Selections remembered for the document at hand alone: a page load drops
// them, a Turbo visit to another document misses the key.
export function documentKey():string {
  return typeof window === 'undefined' ? '' : window.location.pathname;
}
