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

import { ApplicationController } from 'stimulus-use';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';
export default class ModeSwitchRadioController extends ApplicationController {
  static targets = ['radio'];

  declare readonly radioTargets:HTMLInputElement[];

  private committed:HTMLInputElement | undefined;

  connect() {
    this.committed = this.radioTargets.find((radio) => radio.checked);
  }

  select(event:Event):void {
    const radio = event.target as HTMLInputElement;
    if (!radio.checked || radio === this.committed) return;

    const url = radio.dataset.dialogUrl;

    if (this.committed) this.committed.checked = true;

    if (url) this.openDialog(url);
  }

  private openDialog(url:string):void {
    TurboHelpers.showProgressBar();

    void fetch(url, {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    })
      .then((response) => response.text())
      .then((html) => renderStreamMessage(html))
      .finally(() => TurboHelpers.hideProgressBar());
  }
}
