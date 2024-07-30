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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
} from '@angular/core';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface ConfirmDialogOptions {
  text:{
    title:string;
    text:string;
    button_continue?:string;
    button_cancel?:string;
  };
  icon?:{
    continue?:string;
    cancel?:string;
  };
  closeByEscape?:boolean;
  showClose?:boolean;
  closeByDocument?:boolean;
  showListData?:boolean;
  refreshOnCancel?:boolean;
  listTitle?:string;
  warningText?:string;
  passedData?:string[];
  dangerHighlighting?:boolean;
  divideContent?:boolean;
}

@Component({
  templateUrl: './confirm-dialog.modal.html',
  styleUrls: ['./confirm-dialog.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmDialogModalComponent extends OpModalComponent {
  public showClose:boolean;

  public showListData:boolean;

  public refreshOnCancel:boolean;

  public listTitle:string;

  public warningText:string;

  public divideContent:boolean;

  public confirmed = false;

  private options:ConfirmDialogOptions;

  public text = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    button_continue: this.I18n.t('js.button_continue'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  public icon = {
    continue: undefined,
    cancel: undefined,
  };

  public passedData:string[];

  public dangerHighlighting:boolean;

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) {
    super(locals, cdRef, elementRef);
    this.options = (locals.options || {}) as ConfirmDialogOptions;

    this.dangerHighlighting = _.defaultTo(this.options.dangerHighlighting, false);
    this.showListData = _.defaultTo(this.options.showListData, false);
    this.refreshOnCancel = _.defaultTo(this.options.refreshOnCancel, false);
    this.listTitle = _.defaultTo(this.options.listTitle, '');
    this.warningText = _.defaultTo(this.options.warningText, '');
    this.passedData = _.defaultTo(this.options.passedData, []);
    this.showClose = _.defaultTo(this.options.showClose, true);
    this.divideContent = _.defaultTo(this.options.divideContent, false);
    // override default texts and icons if any
    this.text = _.defaults(this.options.text, this.text);
    this.icon = _.defaults(this.options.icon, this.icon);
  }

  public confirmAndClose(evt:Event):void {
    this.confirmed = true;
    this.closeMe(evt);
  }

  public close(evt:Event):void {
    this.closeMe(evt);
    if (this.refreshOnCancel) {
      window.location.reload();
    }
  }
}
