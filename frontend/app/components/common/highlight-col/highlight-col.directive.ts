// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Directive, ElementRef, OnInit, OnDestroy} from '@angular/core';

@Directive({
  selector: '[highlight-col]'
})

export class HighlightColDirective implements OnInit, OnDestroy {
  private $element:JQuery;

  constructor(private elementRef:ElementRef) {
  }

  ngOnInit() {
    var that = this;
    this.$element = jQuery(this.elementRef.nativeElement);
    var thead = this.$element.parent('colgroup').siblings('thead');

    // Separte handling instead of toggle is neccessary to avoid
    // unwanted side effects when adding/removing columns via keyboard in the modal
    thead.on('mouseenter', 'th', function(evt:JQueryEventObject) {
      if (that.$element.index() === jQuery(evt.currentTarget).index()) {
        that.$element.addClass('hover');
      }
    });
    thead.on('mouseleave', 'th', function(evt:JQueryEventObject) {
      if (that.$element.index() === jQuery(evt.currentTarget).index()) {
        that.$element.removeClass('hover');
      }
    });
  }

  ngOnDestroy() {
    thead.off('mouseenter mouseleave');
  }
}
