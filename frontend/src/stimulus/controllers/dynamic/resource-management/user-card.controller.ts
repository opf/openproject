/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 *
 */

import { Controller } from '@hotwired/stimulus';
import { renderStreamMessage } from '@hotwired/turbo';
import { closestInteractiveElement } from 'core-stimulus/helpers/interactive-element-helper';

export default class UserCardController extends Controller<HTMLElement> {
  static values = { url: String };

  declare readonly urlValue:string;

  connect():void {
    this.element.addEventListener('click', this.onClick);
  }

  disconnect():void {
    this.element.removeEventListener('click', this.onClick);
  }

  private onClick = (event:MouseEvent):void => {
    if (this.fromInteractiveElement(event)) {
      return;
    }

    void this.openDialog();
  };

  private fromInteractiveElement(event:Event):boolean {
    return closestInteractiveElement(event.target as Element | null, this.element) !== null;
  }

  private async openDialog():Promise<void> {
    await fetch(this.urlValue, {
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    }).then((response) => response.text())
      .then((html) => renderStreamMessage(html));
  }
}
