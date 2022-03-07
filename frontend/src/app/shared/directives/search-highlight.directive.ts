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

  ngAfterViewChecked() {
    if (!this.query) {
      return;
    }


    const textNode = Array.from(this.elementRef.nativeElement.childNodes).find((n:Node) => n.nodeType === n.TEXT_NODE) as Node|undefined;
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
    this.elementRef.nativeElement.replaceChild(newNode, textNode);
  }
}
