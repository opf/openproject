
import {debugLog} from '../../../helpers/debug_output';
export namespace ClickPositionMapper {

  /**
   * Try to set the position on the given input element.
   *
   * @param element The element to set the cursor to
   * @param offset The character offset retrieved from getPosition.
   */
  export function setPosition(element:JQuery, offset:number):void {
    try {
      (element[0] as HTMLInputElement).setSelectionRange(offset, offset);
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
  export function getPosition(evt:JQueryEventObject):number {
    try {
      const range = document.caretRangeFromPoint(evt.clientX, evt.clientY);
      return range.startOffset;
    } catch (e) {
      debugLog('Failed to get click position for edit field.', e);
      return 0;
    }
  }
}
