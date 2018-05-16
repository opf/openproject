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

import {opUiComponentsModule} from '../../angular-modules';
import {ElementRef, ViewChild, HostListener, Component} from '@angular/core';
import {Directive, OnInit, Inject, Input, EventEmitter, Output} from '@angular/core';
import {I18nToken} from '../../angular4-transition-utils';
import {openprojectModule} from '../../angular-modules';
import {downgradeComponent} from '@angular/upgrade/static';
import {FocusHelperService} from '../common/focus/focus-helper';


@Component({
  selector: 'expandable-search',
  template: require('!!raw-loader!./expandable-search.component.html')
})

export class ExpandableSearchComponent implements OnInit {
  @ViewChild('inputEl') input:ElementRef;
  @ViewChild('btn') btn:ElementRef;
  @ViewChild('searchicon') icon:ElementRef;

  public collapsed:boolean = true;
  public focused:boolean = false;

  constructor(readonly FocusHelper:FocusHelperService,
              @Inject(I18nToken) public I18n:op.I18n) { }

  ngOnInit() { }

  // detect if click is outside or inside the element
  @HostListener('document:click', ['$event']) public handleClick(event:any){
    let clickedEl = event.target;
    if (clickedEl === this.input.nativeElement) return;
    if (clickedEl === this.icon.nativeElement || clickedEl === this.btn.nativeElement) {
      event.stopPropagation();
      if(this.collapsed) {
        // case 1: if collapsed, expand search bar
        this.collapsed = false;
        this.FocusHelper.focusElement(angular.element(this.input.nativeElement));

      } else {
        // case 2: if already collapsed and search string is not empty, submit form
        if (this.input.nativeElement.value != '') {
        	let form = jQuery(clickedEl).closest("form");
                console.log("CLOSEST FORM:", form);
                form.submit();
        } else this.collapsed = true;
      }
    } else {
    // if clicked outside the element
    this.collapsed = true;
    // clear text field for next search
    this.input.nativeElement.value = '';
    }
  }
}


openprojectModule.directive('expandableSearch',
  downgradeComponent({component: ExpandableSearchComponent })
);
