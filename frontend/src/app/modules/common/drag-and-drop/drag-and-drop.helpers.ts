export namespace DragAndDropHelpers {
  export function findIndex(el:HTMLElement):number {
    if (!el.parentElement) {
      return -1;
    }

    const children = Array.from(el.parentElement.children);
    return children.indexOf(el);
  }

  export function reinsert(el:HTMLElement, previousIndex:number|string, container:HTMLElement) {
    previousIndex = typeof previousIndex === 'string' ? parseInt(previousIndex, 10) : previousIndex;
    const currentIndex = el.parentNode && Array.from(el.parentNode.children).indexOf(el) || null;
    const children = Array.from(container.children);
    let pointOfInsertion;

    if (currentIndex != null) {
      const isDraggingDown = currentIndex > previousIndex;
      pointOfInsertion = isDraggingDown ? children[previousIndex] : children[previousIndex + 1];
    } else {
      pointOfInsertion = children[previousIndex];
    }

    if (pointOfInsertion) {
      container.insertBefore(el, pointOfInsertion);
    } else {
      container.appendChild(el);
    }
  }
}
