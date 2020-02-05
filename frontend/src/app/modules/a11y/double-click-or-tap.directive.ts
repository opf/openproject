//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {Directive, EventEmitter, HostListener, Input, Output} from '@angular/core';

@Directive({
  selector: '[doubleClickOrTap]',
})
export class DoubleClickOrTapDirective {
  @Input('doubleClickOrTapStopEvent') stopEventPropagation:boolean = true;
  @Output('doubleClickOrTap') eventHandler = new EventEmitter<any>();

  @HostListener('dblclick', ['$event'])
  @HostListener('tap', ['$event'])
  public handleClick(event:any):boolean {
    // Pass along double clicks immediately
    // Or when the hammer.js event tap count reaches two
    if (event.type === 'dblclick' || event.tapCount === 2) {
      this.eventHandler.emit(event);
      return this.eventStopReturnCode(event);
    }


    return true;
  }

  /**
   * If requested to stop event propagation, stop it
   * and return false.
   * Otherwise, return true.
   *
   * @param event Event being handled
   */
  private eventStopReturnCode(event:Event):boolean {
    if (this.stopEventPropagation) {
      event.preventDefault();

      if (!!event.stopPropagation) {
        event.stopPropagation();
      }

      return false;
    }

    return true;
  }
}
