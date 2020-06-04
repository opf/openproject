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
import {ChangeDetectorRef, Component, ElementRef, Inject} from "@angular/core";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

export interface ConfirmDialogOptions {
  text:{
    title:string;
    text:string;
    button_continue?:string;
    button_cancel?:string;
  };
  closeByEscape?:boolean;
  showClose?:boolean;
  closeByDocument?:boolean;
  passedData?:string[];
  dangerHighlighting?:boolean;
}

@Component({
  templateUrl: './confirm-dialog.modal.html'
})
export class ConfirmDialogModal extends OpModalComponent {

  public showClose:boolean;

  public confirmed = false;

  private options:ConfirmDialogOptions;

  public text:any = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    button_continue: this.I18n.t('js.button_continue'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title')
  };

  public passedData:string[];

  public dangerHighlighting:boolean;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);
    this.options = locals.options || {};

    this.dangerHighlighting = _.defaultTo(this.options.dangerHighlighting, false);
    this.passedData = _.defaultTo(this.options.passedData, []);
    this.closeOnEscape = _.defaultTo(this.options.closeByEscape, true);
    this.closeOnOutsideClick = _.defaultTo(this.options.closeByDocument, true);
    this.showClose = _.defaultTo(this.options.showClose, true);
    // override default texts if any
    this.text = _.defaults(this.options.text, this.text);
  }

  public confirmAndClose(evt:JQuery.TriggeredEvent) {
    this.confirmed = true;
    this.closeMe(evt);
  }
}

