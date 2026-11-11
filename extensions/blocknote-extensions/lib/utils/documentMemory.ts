// Kept for the document at hand alone: a page load drops it, a Turbo visit to
// another document misses the key.
function documentKey():string {
  return typeof window === 'undefined' ? '' : window.location.pathname;
}

export function createDocumentMemory<T>() {
  let remembered:{ document:string, value:T } | undefined;

  return {
    recall: ():T | undefined => (remembered?.document === documentKey() ? remembered.value : undefined),
    remember: (value:T):void => { remembered = { document: documentKey(), value }; },
    forget: ():void => { remembered = undefined; },
  };
}
