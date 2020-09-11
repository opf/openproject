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

    const children = Array.from(container.children);
    const currentIndex = Array.from(el.parentNode!.children).indexOf(el);
    const isDraggingDown = currentIndex > previousIndex;
    const pointOfInsertion = isDraggingDown ? children[previousIndex] : children[previousIndex + 1];

    if (pointOfInsertion) {
      container.insertBefore(el, pointOfInsertion);
    } else {
      container.appendChild(el);
    }
  }
}
