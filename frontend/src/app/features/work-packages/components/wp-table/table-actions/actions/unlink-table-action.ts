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

import {
  contextColumnIcon,
  OpTableAction,
  OpTableActionFactory,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';
import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

export class OpUnlinkTableAction extends OpTableAction {
  constructor(public injector:Injector,
    public workPackage:WorkPackageResource,
    public readonly identifier:string,
    private title:string,
    readonly applicable:(workPackage:WorkPackageResource) => boolean,
    readonly onClick:(workPackage:WorkPackageResource) => void) {
    super(injector, workPackage);
  }

  /**
   *  Returns a factory for this action with the given title and identifier for reusing
   *  remove actions.
   *
   * @param {string} identifier
   * @param {string} title
   */
  public static factoryFor(identifier:string,
    title:string,
    onClick:(workPackage:WorkPackageResource) => void,
    applicable:(workPackage:WorkPackageResource) => boolean = () => true):OpTableActionFactory {
    return (injector:Injector, workPackage:WorkPackageResource) => new OpUnlinkTableAction(injector,
      workPackage,
      identifier,
      title,
      applicable,
      onClick);
  }

  public buildElement() {
    if (!this.applicable(this.workPackage)) {
      return null;
    }

    const element = document.createElement('a');
    element.title = this.title;
    element.href = '#';
    element.classList.add(contextColumnIcon, 'wp-table-action--unlink');
    element.dataset.workPackageId = this.workPackage.id!;
    element.appendChild(opIconElement('icon', 'icon-close'));
    element.addEventListener('click', (event) => {
      event.preventDefault();
      this.onClick(this.workPackage);
    });

    return element;
  }
}
