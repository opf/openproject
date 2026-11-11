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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';

/** Registers the service's overlay and window listeners as the application does; the returned cleanup removes both. */
export function registerContextMenu(service:OPContextMenuService):() => void {
  const listeners:[string, EventListenerOrEventListenerObject][] = [];
  const addEventListener = window.addEventListener.bind(window);
  const spy = vi.spyOn(window, 'addEventListener').mockImplementation((type:string, listener:EventListenerOrEventListenerObject, options?:boolean|AddEventListenerOptions) => {
    listeners.push([type, listener]);
    addEventListener(type, listener, options);
  });
  try {
    service.register();
  } finally {
    spy.mockRestore();
  }

  return () => {
    listeners.forEach(([type, listener]) => window.removeEventListener(type, listener));
    document.querySelector('.op-context-menu--overlay')?.remove();
  };
}
