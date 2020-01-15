// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, OnInit, OnDestroy} from '@angular/core';

@Component({
  selector: 'col[highlight-col]',
  template: ''
})

export class HighlightColDirective implements OnInit, OnDestroy {
  private $element:JQuery;
  private thead:JQuery;

  constructor(private elementRef:ElementRef) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
    this.thead = this.$element
      .parent('colgroup')
      .siblings('thead');

    // Separate handling instead of toggle is necessary to avoid
    // unwanted side effects when adding/removing columns via keyboard in the modal
    this.thead.on('mouseenter', 'th', (evt:JQuery.TriggeredEvent) => {
      if (this.$element.index() === jQuery(evt.currentTarget).index()) {
        this.$element.addClass('hover');
      }
    });

    this.thead.on('mouseleave', 'th', (evt:JQuery.TriggeredEvent) => {
      if (this.$element.index() === jQuery(evt.currentTarget).index()) {
        this.$element.removeClass('hover');
      }
    });
  }

  ngOnDestroy() {
    this.thead.off('mouseenter mouseleave');
  }
}

export const highlightColBootstrap = {
  selector: 'col[highlight-col]',
  cls: HighlightColDirective
};
