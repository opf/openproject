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

import SelectPanelQuickFilterController from './select-panel.controller';

interface CheckedNodePayload {
  path?:string[];
  nodeId?:string;
  value?:string;
}

export default class TreePanelQuickFilterController extends SelectPanelQuickFilterController {
  apply(event:Event) {
    event.stopPropagation();

    this.visitWith(this.checkedNodeIds());
  }

  private checkedNodeIds():string[] {
    const inputs = this.element.querySelectorAll<HTMLInputElement>('input[type=hidden]');

    return Array.from(inputs)
      .map((input) => this.nodeIdFrom(input.value))
      .filter((id):id is string => id !== null);
  }

  private nodeIdFrom(value:string):string|null {
    if (!value.startsWith('{')) return null;

    try {
      return (JSON.parse(value) as CheckedNodePayload).nodeId ?? null;
    } catch {
      return null;
    }
  }
}
