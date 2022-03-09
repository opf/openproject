import {
  AfterViewChecked,
  Directive,
  ElementRef,
  Input,
} from '@angular/core';

@Directive({
  selector: '[opSearchHighlight]',
})
export class OpSearchHighlightDirective implements AfterViewChecked {
  @Input('opSearchHighlight') public query = '';

  constructor(readonly elementRef:ElementRef) { }

  ngAfterViewChecked():void {
    if (!this.query) {
      return;
    }

    const el = this.elementRef.nativeElement as HTMLElement;

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
    newNode.innerHTML = `${start}<span class="op-search-highlight">${result}</span>${end}`;
    el.replaceChild(newNode, textNode);
  }
}
