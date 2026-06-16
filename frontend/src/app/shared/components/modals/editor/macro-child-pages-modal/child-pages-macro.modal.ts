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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, ViewChild, inject } from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  templateUrl: './child-pages-macro.modal.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class ChildPagesMacroModalComponent extends OpModalComponent implements AfterViewInit {
  readonly I18n = inject(I18nService);

  public changed = false;

  public showClose = true;

  public selectedPage:string;

  public selectedIncludeParent:boolean;

  public page = '';

  public includeParent = false;

  @ViewChild('selectedPageInput', { static: true }) selectedPageInput:ElementRef;

  public text:any = {
    title: this.I18n.t('js.editor.macro.child_pages.button'),
    hint: this.I18n.t('js.editor.macro.child_pages.hint'),
    page: this.I18n.t('js.editor.macro.child_pages.page'),
    include_parent: this.I18n.t('js.editor.macro.child_pages.include_parent'),
    button_save: this.I18n.t('js.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  constructor() {
    super();

    this.selectedPage = this.page = this.locals.page;
    this.selectedIncludeParent = this.includeParent = this.locals.includeParent;

    // We could provide an autocompleter here to get correct page names
  }

  public applyAndClose(evt:Event):void {
    this.changed = true;
    this.page = this.selectedPage;
    this.includeParent = this.selectedIncludeParent;
    this.closeMe(evt);
  }

  ngAfterViewInit():void {
    this.selectedPageInput.nativeElement.focus();
  }

  updateIncludeParent(val:boolean):void {
    this.selectedIncludeParent = val;
  }
}
