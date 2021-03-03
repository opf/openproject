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

import { ConfirmDialogModal } from "core-components/modals/confirm-dialog/confirm-dialog.modal";
import { Component, ElementRef, OnInit, ViewChild } from "@angular/core";

@Component({
  templateUrl: './password-confirmation.modal.html'
})
export class PasswordConfirmationModal extends ConfirmDialogModal implements OnInit {

  public password_confirmation:string|null = null;

  @ViewChild('passwordConfirmationField', { static: true }) passwordConfirmationField:ElementRef;

  public ngOnInit() {
    super.ngOnInit();

    this.text.title = I18n.t('js.password_confirmation.title');
    this.text.field_description = I18n.t('js.password_confirmation.field_description');
    this.text.confirm_button = I18n.t('js.button_confirm');
    this.text.password = I18n.t('js.label_password');

    this.closeOnEscape = false;
    this.closeOnOutsideClick = false;
    this.showClose = false;
  }

  public confirmAndClose(evt:JQuery.TriggeredEvent) {
    if (this.passwordValuePresent()) {
      super.confirmAndClose(evt);
    }
  }

  public onOpen(modalElement:JQuery) {
    super.onOpen(modalElement);
    this.passwordConfirmationField.nativeElement.focus();
  }

  public passwordValuePresent() {
    return this.password_confirmation !== null && this.password_confirmation.length > 0;
  }
}
