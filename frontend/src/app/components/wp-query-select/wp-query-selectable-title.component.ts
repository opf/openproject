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
import {StateService, TransitionService} from '@uirouter/core';
import {States} from 'core-components/states.service';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {keyCodes} from 'core-app/modules/common/keyCodes.enum';

@Component({
  selector: 'wp-query-selectable-title',
  templateUrl: './wp-query-selectable-title.html',
})
export class WorkPackageQuerySelectableTitleComponent implements OnInit {
  @Input('selectedTitle') public selectedTitle:string;
  @Input('currentQuery') public currentQuery:QueryResource;
  @Input() disabled:boolean = false;

  private prevValue:string = '';    // The value before editing again
  public editing:boolean = false;
  public duplicateTitle:boolean = false;

  public text = {
    search_query_title: this.I18n.t('js.toolbar.search_query_title'),
    confirm_edit_cancel: this.I18n.t('js.work_packages.query.confirm_edit_cancel'),
    duplicate_query_title: this.I18n.t('js.work_packages.query.errors.duplicate_query_title')
  };

  private unregisterTransitionListener:Function;

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly wpListService:WorkPackagesListService,
              readonly QueryDm:QueryDmService,
              readonly $transitions:TransitionService,
              readonly $state:StateService,
              readonly states:States) {
  }

  ngOnInit() {
    // Listen on esc keypress (this event is not fired by accessible click directive)
      jQuery(window).keydown( (event:JQueryKeyEventObject) => {
        if (jQuery('wp-query-selectable-title').find('input').is( ":focus" ) && this.editing && event.which === keyCodes.ESCAPE) {
          this.cancelEdit();
        }
        return true;
      });
    // Register click on work packages table and cancel edit (set field back to previous value)
    setTimeout( () => {
      jQuery('table').dblclick( (event:JQueryKeyEventObject) => {
        if (this.isEmpty) { this.cancelEdit(); }
      });
    });
    // Register click on work packages and cancel edit
    this.unregisterTransitionListener = this.$transitions.onSuccess({}, (transition) => {
      this.cancelEdit();
      setTimeout( () => jQuery('.notification-box.-error').hide());
    });
  }

  ngOnDestroy() {
    this.unregisterTransitionListener();
  }

  // Edit value of input field if not disabled
  public edit(title:string) {
    // If query is static, the name should not be editable
    if (this.disabled) {
      return;
    }
    // Remember previous value as default (in case input is empty/dublicate, title will be set back to this value)
    if (this.selectedTitle.trim() !== '') {
      this.prevValue = this.selectedTitle;
    }
    this.editing = true;
    // Set focus on input element, when clicked inside
    setTimeout( () => jQuery('wp-query-selectable-title').find('input').focus());
  }

  // Press Enter to save new title
  public onKeyPress(event:JQueryEventObject) {
    switch (event.keyCode) {
      case 32: // SPACE
        this.setBlank(event.target as HTMLInputElement); break;
      case 13: // ENTER
        if (this.editing) {
          this.renameView(); break;
        } else {
          this.edit(this.selectedTitle); break;
        }
      default:
        return;
    }
  }

  // Element looses focus on click outside and is not editable anymore
  private renameView() {
    this.selectedTitle = this.selectedTitle.trim();
    // If the title is not empty and there is a new value in input field, check if name allowed (not duplicat)
    if (!this.isEmpty) {
      if (this.prevValue === this.selectedTitle) {
        return; // Nothing changed
      } else {
        this.checkDuplicateName();
      }
    } else {
      this.updateItemInMenu();  // Throws an error message, when name is empty
      this.focusInputOnError();
    }
  }

  //Search if new name is already assigned to another query and if so, open confirmation
  private checkDuplicateName() {
    this.QueryDm.all(this.currentQuery.project.identifier)
    .then( collection => {
      let itemsWithSameName = collection.elements.filter( query => query.name === this.selectedTitle);
      if (itemsWithSameName.length > 0) {
        this.selectedTitle = this.selectedTitle + ' (2)';
      }
      this.updateItemInMenu();
    });
  }

  // Send new query name to service to update the name in the menu
  private updateItemInMenu() {
    this.currentQuery.name = this.selectedTitle;
    this.wpListService.save(this.currentQuery);
  }

  // Blank spaces have to be set manually, otherwise the space keypress will be ignored
  private setBlank(input:HTMLInputElement) {
    let cursorPos:number = input.selectionStart;
    this.selectedTitle = this.selectedTitle.slice(0, cursorPos) + ' ' + this.selectedTitle.slice(cursorPos);
    setTimeout( () => input.setSelectionRange(cursorPos + 1, cursorPos + 1));
  }

  private cancelEdit() {
    this.editing = false;
    this.currentQuery.name = this.selectedTitle = this.prevValue;
  }

  private get errorState():boolean {
    if (this.isEmpty || this.duplicateTitle) {
      return true;
    } else {
      return false;
    }
  }

  private focusInputOnError() {
    setTimeout( () => {
      let input = jQuery('wp-query-selectable-title').find('input');
      input.addClass('-error').focus();
    });
  }

  // Check if title of query is empty
  private get isEmpty():boolean {
    if (this.selectedTitle === '') {
      return this.editing = true;
    } else {
      return this.editing = false;
    }
  }
}
