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
import {Component, ElementRef, Input, OnInit, ViewChild} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackagesListService} from 'core-components/wp-list/wp-list.service';
import {StateService, TransitionService} from '@uirouter/core';
import {States} from 'core-components/states.service';

@Component({
  selector: 'wp-query-selectable-title',
  templateUrl: './wp-query-selectable-title.html',
  host: { 'class': 'title-container' }
})
export class WorkPackageQuerySelectableTitleComponent implements OnInit {
  @Input() public selectedTitle:string;
  @Input() public currentQuery:QueryResource;
  @Input() editable:boolean = true;

  @ViewChild('editableTitleInput') inputField?:ElementRef;

  public inFlight:boolean = false;

  public text = {
    click_to_edit: this.I18n.t('js.work_packages.query.click_to_edit_query_name'),
    press_enter_to_save: this.I18n.t('js.label_press_enter_to_save'),
    input_title: '',
    search_query_title: this.I18n.t('js.toolbar.search_query_title'),
    confirm_edit_cancel: this.I18n.t('js.work_packages.query.confirm_edit_cancel'),
    duplicate_query_title: this.I18n.t('js.work_packages.query.errors.duplicate_query_title')
  };


  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              readonly wpListService:WorkPackagesListService,
              readonly $transitions:TransitionService,
              readonly $state:StateService,
              readonly states:States) {
  }

  ngOnInit() {
    this.text['input_title'] = `${this.text.click_to_edit} ${this.text.press_enter_to_save}`;
  }

  public reset() {
    this.resetInputField();
    this.selectedTitle = this.currentTitle;
  }

  // Element looses focus on click outside and is not editable anymore
  public save($event:Event) {
    $event.preventDefault();

    this.resetInputField();
    this.selectedTitle = this.selectedTitle.trim();

    // If the title is empty, show an error
    if (this.isEmpty) {
      this.updateItemInMenu();  // Throws an error message, when name is empty
      this.focusInputOnError();
      return;
    }

    if (this.currentTitle === this.selectedTitle) {
      return; // Nothing changed
    }

    this.updateItemInMenu();
  }

  /**
   * The current saved title
   */
  private get currentTitle():string {
    return this.currentQuery.name;
  }

  // Send new query name to service to update the name in the menu
  private updateItemInMenu() {
    this.inFlight = true
    this.currentQuery.name = this.selectedTitle;
    this.wpListService.save(this.currentQuery)
      .then(() => this.inFlight = false)
      .catch(() => this.inFlight = false);
  }

  private focusInputOnError() {
    if (this.inputField) {
      const el = this.inputField.nativeElement;
      el.classList.add('-error');
      el.focus();
    }
  }

  private resetInputField() {
    if (this.inputField) {
      const el = this.inputField.nativeElement;
      el.classList.remove('-error');
    }
  }

  // Check if title of query is empty
  private get isEmpty():boolean {
    return this.selectedTitle === '';
  }
}
