//-- copyright
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
//++
import {ViewChild, Component, forwardRef, OnInit, ElementRef, Inject, Input} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';

@Component({
  selector: 'wp-query-selectable-title',
  templateUrl: './wp-query-selectable-title.html',
})
export class WorkPackageQuerySelectableTitleComponent implements OnInit {
  @Input('selectedTitle') public selectedTitle:string;
  @Input('currentQuery') public currentQuery:QueryResource;
  @Input() disabled:boolean = false; // Is input disabled?

  private defaultValue:string = ''; // The value before clicking to edit
  public editing:boolean = false; // Is Component in edit mode?
  private prevValue:string = '';

  public text = {
    search_query_title: this.I18n.t('js.toolbar.search_query_title')
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly wpListService:WorkPackagesListService) {
  }

  ngOnInit() {
  }

  // Element looses focus on click outside and is not editable anymore
  onBlur(event:JQueryEventObject) {
    if (this.empty) {
      this.editing = true;
    } else {
      this.editing = false;
      this.setTitle();
    }
  }

  // Press Enter to save new title
  onKeyPress(event:JQueryEventObject) {
    if (event.keyCode === 13 && !this.empty) {
        this.editing = false;
        this.setTitle();
    } else this.editing = true;
  }

  private setTitle() {
    if (this.prevValue !== this.selectedTitle) {
      this.currentQuery.name = this.selectedTitle;
      this.wpListService.save(this.currentQuery);
    }
  }

  private get empty() {
    if (this.selectedTitle === '') {
      return true;
    } else return false;
  }

  // Edit value of input field
  public edit(title:string) {
    if (this.disabled) {
      return;
    }
    // Remember start value as default (in case input is empty, title will be set back to default value)
    if (this.defaultValue === '') {
      this.defaultValue = title;
    }
    this.prevValue = this.selectedTitle;
    this.editing = true;
    // Set focus on input element, when clicked inside
     setTimeout( () => jQuery('wp-query-selectable-title').find('input').focus())
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {JQueryEventObject} openerEvent
   */
  public positionArgs(openerEvent:JQueryEventObject) {
    return {
      my: 'left top',
      at: 'left bottom',
      of: jQuery(this.elementRef).find('.wp-table--query-menu-link')
    };
  }
}
