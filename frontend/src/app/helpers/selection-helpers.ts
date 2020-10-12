export namespace SelectionHelpers {

  /**
   * Test whether we currently have a selection within.
   * @param {HTMLElement} target
   * @return {boolean}
   */
  export function hasSelectionWithin(target:Element):boolean {
    try {
      const selection = window.getSelection()!;
      const hasSelection = selection.toString().length > 0;
      const isWithin = target.contains(selection.anchorNode);

      return hasSelection && isWithin;
    } catch (e) {
      console.error('Failed to test whether in selection ', e);
      return false;
    }
  }
}

