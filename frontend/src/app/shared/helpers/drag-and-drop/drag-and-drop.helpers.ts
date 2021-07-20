export function findIndex(el:HTMLElement):number {
  if (!el.parentElement) {
    return -1;
  }

  const children = Array.from(el.parentElement.children);
  return children.indexOf(el);
}

export function reinsert(el:HTMLElement, previousIndex:number|string, container:HTMLElement) {
  const prev = typeof previousIndex === 'string' ? parseInt(previousIndex, 10) : previousIndex;
  const currentIndex = el.parentNode ? Array.from(el.parentNode.children).indexOf(el) : null;
  const children = Array.from(container.children);

  const pointOfInsertion = (() => {
    if (currentIndex != null && currentIndex >= 0) {
      const isDraggingDown = currentIndex > prev;
      return isDraggingDown ? children[prev] : children[prev + 1];
    }

    return children[prev];
  })();

  if (pointOfInsertion) {
    container.insertBefore(el, pointOfInsertion);
  } else {
    container.appendChild(el);
  }
}
