/**
 * Return the row html id attribute for the given work package ID.
 */
import { collapsedGroupClass } from "core-components/wp-fast-table/helpers/wp-table-hierarchy-helpers";

export function rowId(workPackageId:string):string {
  return `wp-row-${workPackageId}-table`;
}

export function relationRowClass():string {
  return `wp-table--relations-aditional-row`;
}

export function locateTableRow(workPackageId:string):JQuery {
  return jQuery('.' + rowId(workPackageId));
}

export function locateTableRowByIdentifier(identifier:string) {
  return jQuery(`.${identifier}-table`);
}

export function isInsideCollapsedGroup(el?:Element | null) {
  if (!el) {
    return false;
  }

  return Array.from(el.classList).find(listClass => listClass.includes(collapsedGroupClass())) != null;
}

export function locatePredecessorBySelector(el:HTMLElement, selector:string):HTMLElement|null {
  let previous = el.previousElementSibling;

  while (previous) {
    if (previous.matches(selector)) {
      return previous as HTMLElement;
    } else {
      previous = previous.previousElementSibling;
    }
  }

  return null;
}

export function scrollTableRowIntoView(workPackageId:string):void {
  try {
    const element = locateTableRow(workPackageId);
    const container = element.scrollParent()!;
    const containerTop = container.scrollTop()!;
    const containerBottom = containerTop + container.height()!;

    const elemTop = element[0].offsetTop;
    const elemBottom = elemTop + element.height()!;

    if (elemTop < containerTop) {
      container[0].scrollTop = elemTop;
    } else if (elemBottom > containerBottom) {
      container[0].scrollTop = elemBottom - container.height()!;
    }
  } catch (e) {
    console.warn("Can't scroll row element into view: " + e);
  }
}
