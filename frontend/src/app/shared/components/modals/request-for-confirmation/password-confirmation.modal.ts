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
  Component,
  ElementRef,
  OnInit,
  ViewChild,
} from '@angular/core';

import { ConfirmDialogModalComponent } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';

@Component({
  templateUrl: './password-confirmation.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PasswordConfirmationModalComponent extends ConfirmDialogModalComponent implements OnInit {
  public password_confirmation:string|null = null;

  @ViewChild('passwordConfirmationField', { static: true }) passwordConfirmationField:ElementRef;

  public additionalText = {
    field_description: I18n.t('js.password_confirmation.field_description'),
    confirm_button: I18n.t('js.button_confirm'),
    password: I18n.t('js.label_password'),
    cancel_button: I18n.t('js.button_cancel'),
  };

  public ngOnInit():void {
    super.ngOnInit();

    this.text.title = I18n.t('js.password_confirmation.title');
    this.showClose = false;
  }

  public confirmAndClose(evt:Event):void {
    if (this.passwordValuePresent()) {
      super.confirmAndClose(evt);
    }
  }

  public onOpen():void {
    super.onOpen();
    this.passwordConfirmationField.nativeElement.focus();
  }

  public passwordValuePresent():boolean {
    return this.password_confirmation !== null && this.password_confirmation.length > 0;
  }
}
