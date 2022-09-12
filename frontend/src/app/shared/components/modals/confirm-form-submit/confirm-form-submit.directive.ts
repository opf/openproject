// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Component, ElementRef, Input, OnInit } from '@angular/core';
import { ConfirmDialogService } from '../confirm-dialog/confirm-dialog.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export const confirmFormSubmitSelector = 'confirm-form-submit';

@Component({
  template: '',
  selector: confirmFormSubmitSelector,
})
export class ConfirmFormSubmitController implements OnInit {
  @Input() public dangerHighlighting = false;

  @Input() public modalText = '';

  @Input() public modalTitle = '';

  // Allow original form submission after dialog was closed
  public confirmed = false;

  private $element:JQuery<HTMLElement>;

  private $form:JQuery<HTMLElement>;

  constructor(readonly elementRef:ElementRef,
    readonly confirmDialog:ConfirmDialogService,
    readonly I18n:I18nService) {
    populateInputsFromDataset(this);
  }

  ngOnInit() {
    this.$element = jQuery<HTMLElement>(this.elementRef.nativeElement);

    if (this.$element.is('form')) {
      this.$form = this.$element;
    } else {
      this.$form = this.$element.closest('form');
    }

    this.$form.on('submit', (evt) => {
      if (!this.confirmed) {
        evt.preventDefault();
        this.openConfirmationDialog();
        return false;
      }

      return true;
    });
  }

  public openConfirmationDialog() {
    this.confirmDialog.confirm({
      text: {
        title: this.modalTitle === '' ? this.I18n.t('js.modals.form_submit.title') : this.modalTitle,
        text: this.modalText === '' ? this.I18n.t('js.modals.form_submit.text') : this.modalText,
      },
      closeByEscape: true,
      dangerHighlighting: this.dangerHighlighting,
      showClose: true,
      closeByDocument: true,
    }).then(() => {
      this.confirmed = true;
      this.$form.trigger('submit');
    })
      .catch(() => this.confirmed = false);
  }
}
