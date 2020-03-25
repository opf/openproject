export namespace DomHelpers {
  export function setBodyCursor(cursor:string, priority:'important'|'' = '') {
    document.body.style.setProperty('cursor', cursor, priority);
  }
}