export namespace DragAndDropHelpers {
  export function findIndex(el:HTMLElement):number {
    if (!el.parentElement) {
      return -1;
    }

    const children = Array.from(el.parentElement.children);
    return children.indexOf(el);
  }

  export function reinsert(el:HTMLElement, index:number|string, container:HTMLElement) {
    index = typeof index === 'string' ? parseInt(index, 10) : index;

    const children = Array.from(container.children);

    // Append to end if unknown index or no child nodes
    if (index < 0 || index >= children.length || children.length === 0) {
      container.appendChild(el);
    }

    // Get the element to insert before
    const sibling = children[index];
    if (sibling) {
      container.insertBefore(el, sibling);
    } else {
      container.appendChild(el);
    }
  }
}
