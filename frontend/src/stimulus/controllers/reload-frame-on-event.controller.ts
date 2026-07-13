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
 */

import { Controller } from '@hotwired/stimulus';
import { FrameElement } from '@hotwired/turbo';

// Reloads the turbo-frame this controller is attached to whenever the
// configured document event fires. The frame starts without a `src` (so it is
// not fetched on load); the first event points it at `urlValue`, later events
// reload it. Pair the frame with `refresh="morph"` to reload without flicker.
export default class ReloadFrameOnEventController extends Controller<FrameElement> {
  static values = { eventName: String, url: String };

  declare eventNameValue:string;
  declare urlValue:string;

  private readonly listener = ():void => {
    if (this.element.src) {
      void this.element.reload();
    } else {
      this.element.src = this.urlValue;
    }
  };

  connect():void {
    document.addEventListener(this.eventNameValue, this.listener);
  }

  disconnect():void {
    document.removeEventListener(this.eventNameValue, this.listener);
  }
}
