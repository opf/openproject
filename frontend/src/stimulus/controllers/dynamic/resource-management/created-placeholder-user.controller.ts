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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { DialogCloseDetail } from 'core-turbo/dialog-stream-action';
import { SELECT_PRINCIPAL_EVENT } from 'core-common/resource-allocation-autocompleter';

interface CreatedPlaceholderUser {
  placeholderUserId?:number;
}

export default class CreatedPlaceholderUserController extends Controller<HTMLElement> {
  static values = {
    dialogId: String,
    autocompleter: String,
  };

  declare readonly dialogIdValue:string;
  declare readonly autocompleterValue:string;

  connect():void {
    document.addEventListener('dialog:close', this.onDialogClose);
  }

  disconnect():void {
    document.removeEventListener('dialog:close', this.onDialogClose);
  }

  private onDialogClose = (event:Event):void => {
    const { dialog, submitted, additional } = (event as CustomEvent<DialogCloseDetail>).detail;

    if (dialog.id !== this.dialogIdValue || !submitted) { return; }

    const { placeholderUserId } = (additional ?? {}) as CreatedPlaceholderUser;
    if (!placeholderUserId) { return; }

    this.element.querySelector(this.autocompleterValue)?.dispatchEvent(
      new CustomEvent(SELECT_PRINCIPAL_EVENT, { detail: { id: placeholderUserId.toString() } }),
    );
  };
}
