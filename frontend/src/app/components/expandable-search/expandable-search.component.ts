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

import {Component, ElementRef, HostListener, Inject, OnDestroy, Renderer2, ViewChild} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {ContainHelpers} from "core-app/modules/common/focus/contain-helpers";
import {FocusHelperService} from "core-app/modules/common/focus/focus-helper";

@Component({
  selector: 'expandable-search',
  templateUrl: './expandable-search.component.html'
})

export class ExpandableSearchComponent implements OnDestroy {
  @ViewChild('inputEl') input:ElementRef;
  @ViewChild('btn') btn:ElementRef;

  public collapsed:boolean = true;
  public focused:boolean = false;

  private unregisterGlobalListener:Function|undefined;

  constructor(readonly FocusHelper:FocusHelperService,
              readonly elementRef:ElementRef,
              readonly renderer:Renderer2,
              readonly I18n:I18nService) {
  }

  // detect if click is outside or inside the element
  @HostListener('click', ['$event'])
  public handleClick(event:JQueryEventObject):void {
    event.stopPropagation();
    event.preventDefault();

    // If search is open, submit form when clicked on icon
    if (!this.collapsed && ContainHelpers.insideOrSelf(this.btn.nativeElement, event.target)) {
      this.submitNonEmptySearch();
    }

    if (this.collapsed) {
      this.collapsed = false;
      this.FocusHelper.focusElement(jQuery(this.input.nativeElement));
      this.registerOutsideClick();
    }
  }

  public closeWhenFocussedOutside() {
    ContainHelpers.whenOutside(this.elementRef.nativeElement, () => this.close());
    return false;
  }

  ngOnDestroy() {
    this.unregister();
  }

  private registerOutsideClick() {
    this.unregisterGlobalListener = this.renderer.listen('document', 'click', () => {
      this.close();
    });
  }

  private close() {
    this.collapsed = true;
    this.searchValue = '';
    this.unregister();
  }

  private unregister() {
    if (this.unregisterGlobalListener) {
      this.unregisterGlobalListener();
      this.unregisterGlobalListener = undefined;
    }
  }

  private submitNonEmptySearch() {
    if (this.searchValue !== '') {
      jQuery(this.input.nativeElement)
        .closest("form")
        .submit();
    }
  }

  private get searchValue() {
    return this.input.nativeElement.value;
  }

  private set searchValue(val:string)  {
    this.input.nativeElement.value = val;
  }
}
