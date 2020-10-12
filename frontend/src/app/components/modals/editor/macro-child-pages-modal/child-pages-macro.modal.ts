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

import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {AfterViewInit, ChangeDetectorRef, Component, ElementRef, Inject, ViewChild} from "@angular/core";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './child-pages-macro.modal.html'
})
export class ChildPagesMacroModal extends OpModalComponent implements AfterViewInit {

  public changed = false;
  public showClose = true;
  public closeOnEscape = true;
  public closeOnOutsideClick = true;

  public selectedPage:string;
  public selectedIncludeParent:boolean;
  public page:string = '';
  public includeParent:boolean = false;

  @ViewChild('selectedPageInput', { static: true }) selectedPageInput:ElementRef;

  public text:any = {
    title: this.I18n.t('js.editor.macro.child_pages.button'),
    hint: this.I18n.t('js.editor.macro.child_pages.hint'),
    page: this.I18n.t('js.editor.macro.child_pages.page'),
    include_parent: this.I18n.t('js.editor.macro.child_pages.include_parent'),
    button_save: this.I18n.t('js.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title')
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);
    this.selectedPage = this.page = this.locals.page;
    this.selectedIncludeParent = this.includeParent = this.locals.includeParent;

    // We could provide an autocompleter here to get correct page names
  }

  public applyAndClose(evt:JQuery.TriggeredEvent) {
    this.changed = true;
    this.page = this.selectedPage;
    this.includeParent = this.selectedIncludeParent;
    this.closeMe(evt);
  }

  ngAfterViewInit() {
    this.selectedPageInput.nativeElement.focus();
  }

  updateIncludeParent(val:boolean) {
    this.selectedIncludeParent = val;
  }
}

