import { escape } from 'lodash-es';
import { AfterViewChecked, Directive, ElementRef, Input, inject } from '@angular/core';

@Directive({
  selector: '[opSearchHighlight]',
  standalone: false,
})
export class OpSearchHighlightDirective implements AfterViewChecked {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @Input('opSearchHighlight') public query = '';

  ngAfterViewChecked():void {
    let el = this.elementRef.nativeElement;
    const highlightedElement = el.querySelector('.op-search-highlight');

    if (!!highlightedElement && highlightedElement.innerHTML.toLocaleLowerCase() === this.query?.toLocaleLowerCase()) {
      return;
    }

    el = this.cleanUpOldHighlighting(el);
    if (!this.query) {
      return;
    }

    const textNode = Array.from(el.childNodes).find((n:Node) => n.nodeType === n.TEXT_NODE) as Node;
    const content = textNode?.textContent || '';
    if (!content) {
      return;
    }

    const query = this.query.toLowerCase();
    const startIndex = content.toLowerCase().indexOf(query);
    if (startIndex < 0) {
      return;
    }

    const start = content.slice(0, startIndex);
    const result = content.slice(startIndex, startIndex + query.length);
    const end = content.slice(startIndex + query.length);

    const newNode = document.createElement('span');
    newNode.innerHTML = `${escape(start)}<span class="op-search-highlight">${escape(result)}</span>${escape(end)}`;
    el.replaceChild(newNode, textNode);
  }

  private cleanUpOldHighlighting(el:HTMLElement):HTMLElement {
    if (el.children.length > 0) {
      const unifiedLabelText = Array.from(el.children, ({ textContent }) => textContent?.trim()).join('');
      el.innerHTML = '';
      el.innerText = unifiedLabelText;
    }

    return el;
  }
}
