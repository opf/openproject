import { debugLog } from '../debug_output';

/**
 * Try to set the position on the given input element.
 *
 * @param element The element to set the cursor to
 * @param offset The character offset retrieved from getPosition.
 */
export function setPosition(element:HTMLInputElement, offset:number):void {
  try {
    element.setSelectionRange(offset, offset);
  } catch (e) {
    debugLog('Failed to set click position for edit field.', e);
  }
}

/**
 * Get the cursor offset from the click event.
 *
 * @param evt
 * @return {number}
 */
export function getPosition(evt:any):number {
  const originalEvt = evt.originalEvent;

  try {
    if (originalEvt.rangeParent) {
      const range = document.createRange();
      range.setStart(originalEvt.rangeParent, originalEvt.rangeOffset);
      return range.startOffset;
    }

    if (document.caretRangeFromPoint) {
      return document
        .caretRangeFromPoint(evt.clientX!, evt.clientY!)
        .startOffset;
    }

    return 0;
  } catch (e) {
    debugLog('Failed to get click position for edit field.', e);
    return 0;
  }
}
