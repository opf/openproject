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
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';

@Component({
  selector: 'wp-query-selectable-title',
  templateUrl: './wp-query-selectable-title.html',
})
export class WorkPackageQuerySelectableTitleComponent implements OnInit {
  @Input('selectedTitle') public selectedTitle:string;
  @Input('currentQuery') public currentQuery:QueryResource;
  @Input() disabled:boolean = false;

  private defaultValue:string = ''; // The first saved value before editing
  private prevValue:string = '';    // The value before editing again
  public editing:boolean = false;

  public text = {
    search_query_title: this.I18n.t('js.toolbar.search_query_title'),
    confirm_edit_cancel: this.I18n.t('js.work_packages.query.confirm_edit_cancel'),
    duplicate_query_title: this.I18n.t('js.work_packages.query.errors.duplicate_query_title')
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly wpListService:WorkPackagesListService,
              readonly QueryDm:QueryDmService) {
  }

  ngOnInit() {
    jQuery(window).on('click', event => this.confirmCancel(event));
  }

  // Edit value of input field if not disabled
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
    setTimeout( () => jQuery('wp-query-selectable-title').find('input').focus());
  }

  private confirmCancel(event:JQueryEventObject) {
    // Check if field is empty and click target is table or menu (the intention was to leave this page)
    if (this.isEmpty && (jQuery(event.target).is('td') || jQuery(event.target).is('.ui-menu-item-wrapper')) ) {
      let confirm = window.confirm(this.text.confirm_edit_cancel);
      // Set title back to saved default and go to click target
      if (confirm) {
        this.editing = false;
        this.selectedTitle = this.defaultValue;
        this.currentQuery.name = this.selectedTitle;
        jQuery(event.target).dblclick();
      } else {
        setTimeout( () => jQuery('wp-query-selectable-title').find('input').focus())
      }
    }
  }

  // Press Enter to save new title
  private onKeyPress(event:JQueryEventObject) {
    if (event.keyCode === 32) {
      this.setBlank(event.target as HTMLInputElement);
    } else if (event.keyCode === 13) {
      this.onBlur();
    }
  }

  // Blank spaces have to be set manually, otherwise the space keypress will be ignored
  private setBlank(input:HTMLInputElement) {
    let cursorPosition:number = input.selectionStart;
    this.selectedTitle = this.selectedTitle.slice(0, cursorPosition) + ' ' + this.selectedTitle.slice(cursorPosition);
    setTimeout( () => input.setSelectionRange(cursorPosition+1, cursorPosition+1));
  }

  // Element looses focus on click outside and is not editable anymore
  private onBlur() {
    this.editing = false;
    this.renameView();
  }

  private renameView() {
    this.selectedTitle = this.selectedTitle.trim();
    // Return if nothing changed
    if (this.prevValue === this.selectedTitle) { return };

    // Search if new name is already assigned to another query and if so, open confirmation
    this.QueryDm.all(this.currentQuery.project.identifier).then(collection => {
      let itemsWithSameName = collection.elements.filter( (query:QueryResource) => query.name === this.selectedTitle);
      if (itemsWithSameName.length > 0) {
        this.confirmRename();
      } else {
        this.closeInput();
      }
    });
  }

  private closeInput() {
    // If the title is empty, input field should stay opened
    if (this.isEmpty) {
      this.editing = true;
    } else {
      this.editing = false;
      // Send new query name to service to also update the name in the menu
      this.currentQuery.name = this.selectedTitle;
      this.wpListService.save(this.currentQuery);
    }
  }

  private confirmRename() {
    let confirm = window.confirm(this.text.duplicate_query_title);
    // Set title back to saved default and go to click target
    if (confirm) {
      this.selectedTitle += ' (2)';
      this.closeInput();
    } else {
      this.editing = true;
      this.focusInputOnError();
    }
  }

  private focusInputOnError() {
    setTimeout( () => {
      let input = jQuery('wp-query-selectable-title').find('input');
      input.addClass('-error').focus();
      input.keydown(function() {
        input.removeClass('-error');
      });
    });
  }

  // Check if title of query is empty
  private get isEmpty():boolean {
    if (this.selectedTitle === '') {
      return true;
    } else {
      return false;
    }
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
