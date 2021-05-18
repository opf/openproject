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

import { Directive, EventEmitter, HostListener, Input, Output } from '@angular/core';
import { LinkHandling } from 'core-app/modules/common/link-handling/link-handling';

@Directive({
  selector: '[accessibleClick]',
})
export class AccessibleClickDirective {
  @Input('accessibleClickStopEvent') stopEventPropagation = true;
  @Input('accessibleClickSkipModifiers') skipEventModifiers = false;
  @Output('accessibleClick') onClick = new EventEmitter<MouseEvent|KeyboardEvent>();

  @HostListener('click', ['$event'])
  @HostListener('keydown', ['$event'])
  public handleClick(event:MouseEvent|KeyboardEvent) {
    if (this.isMatchingEvent(event) && !this.skipOnModifier(event)) {
      if (this.stopEventPropagation) {
        event.preventDefault();
        event.stopPropagation();
      }

      this.onClick.emit(event);
    }
  }

  /**
   * Whether the given event is handled by this directive
   * @param event
   * @private
   */
  private isMatchingEvent(event:MouseEvent|KeyboardEvent) {
    return event.type === 'click' ||
      (event instanceof KeyboardEvent && (event.key === 'Enter' || event.key === ' '));
  }

  /**
   * Whether to skip the click event with modifiers pressed
   * according to the input being set.
   *
   * @param event
   * @private
   */
  private skipOnModifier(event:MouseEvent|KeyboardEvent) {
    return this.skipEventModifiers && event instanceof MouseEvent && LinkHandling.isClickedWithModifier(event);
  }
}
