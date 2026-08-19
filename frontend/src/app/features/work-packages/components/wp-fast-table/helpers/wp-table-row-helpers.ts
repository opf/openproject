/**
 * Return the row html id attribute for the given work package ID.
 */
import { collapsedGroupClass } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';

export function rowId(workPackageId:string):string {
  return `wp-row-${workPackageId}-table`;
}

export function relationRowClass():string {
  return 'wp-table--relations-additional-row';
}

export function locateTableRow(workPackageId:string) {
  return document.querySelector<HTMLTableRowElement>(`.${rowId(workPackageId)}`);
}

export function locateTableRowByIdentifier(identifier:string) {
  return document.querySelector<HTMLTableRowElement>(`.${identifier}-table`);
}

export function isInsideCollapsedGroup(el?:Element | null) {
  if (!el) {
    return false;
  }

  return Array.from(el.classList).find((listClass) => listClass.includes(collapsedGroupClass())) != null;
}

export function locatePredecessorBySelector(el:HTMLElement, selector:string):HTMLElement|null {
  let previous = el.previousElementSibling;

  while (previous) {
    if (previous.matches(selector)) {
      return previous as HTMLElement;
    }
    previous = previous.previousElementSibling;
  }

  return null;
}

export function scrollTableRowIntoView(workPackageId:string):void {
  try {
    const element = locateTableRow(workPackageId)!;
    const container = getScrollParent(element);
    const containerTop = container.scrollTop;
    const containerBottom = containerTop + container.clientHeight;

    const elemTop = element.offsetTop;
    const elemBottom = elemTop + element.offsetHeight;

    if (elemTop < containerTop) {
      container.scrollTop = elemTop;
    } else if (elemBottom > containerBottom) {
      container.scrollTop = elemBottom - container.clientHeight;
    }
  } catch (e) {
    console.warn(`Can't scroll row element into view: ${e}`);
  }
}

function getScrollParent(element:HTMLElement, includeHidden = false) {
  const overflowRegex = includeHidden ? /(auto|scroll|hidden)/ : /(auto|scroll)/;

  let parent:HTMLElement|null = element.parentElement;

  while (parent && parent !== document.body) {
    const style = getComputedStyle(parent);
    const overflow = style.overflow + style.overflowY + style.overflowX;

    if (overflowRegex.test(overflow)) {
      return parent;
    }

    parent = parent.parentElement;
  }

  return document.scrollingElement || document.documentElement;
}
