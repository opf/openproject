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

import { TimelineViewParameters } from '../wp-timeline';

export const timelineStaticElementCssClassname = 'wp-timeline--static-element';

export abstract class TimelineStaticElement {
  constructor() {
  }

  /**
   * Render the static element according to the current ViewParameters
   * @param vp Current timeline view paraemters
   * @returns {HTMLElement} The finished static element
   */
  public render(vp:TimelineViewParameters):HTMLElement {
    const elem = document.createElement('div');
    elem.id = this.identifier;
    elem.classList.add(...this.classNames);

    return this.finishElement(elem, vp);
  }

  protected abstract finishElement(elem:HTMLElement, vp:TimelineViewParameters):HTMLElement;

  public abstract get identifier():string;

  public get classNames():string[] {
    return [timelineStaticElementCssClassname];
  }
}
