//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { ConfirmDialogService } from './../confirm-dialog/confirm-dialog.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { Component, ElementRef, OnInit } from "@angular/core";

export const confirmFormSubmitSelector = 'confirm-form-submit';

@Component({
  template: '',
  selector: confirmFormSubmitSelector
})
export class ConfirmFormSubmitController implements OnInit {

  // Allow original form submission after dialog was closed
  public confirmed = false;
  public text = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text')
  };

  private $element:JQuery<HTMLElement>;
  private $form:JQuery<HTMLElement>;

  constructor(readonly element:ElementRef,
              readonly confirmDialog:ConfirmDialogService,
              readonly I18n:I18nService) {
  }

  ngOnInit() {
    this.$element = jQuery<HTMLElement>(this.element.nativeElement);

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
      text: this.text,
      closeByEscape: true,
      showClose: true,
      closeByDocument: true,
    }).then(() => {
      this.confirmed = true;
      this.$form.trigger('submit');
    })
      .catch(() => this.confirmed = false);
  }
}
