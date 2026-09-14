//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
